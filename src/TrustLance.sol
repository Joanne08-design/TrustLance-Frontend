// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract TrustLance  is ReentrancyGuard{
    enum JobStatus {
        Open,
        CounterOffered,
        AwaitingFreelancerAcceptance,
        AwaitingFunding,
        Active,
        Completed,
        Cancelled
    }

    enum MilestoneStatus {
        Pending,
        Submitted,
        RevisionRequested,
        Disputed,
        Paid,
        Settled
    }

    uint256 public constant REVIEW_PERIOD = 5 days;
    uint256 public constant REVISION_PERIOD = 3 days;
    uint256 public constant MAX_REVISIONS = 2;
    uint256 public constant MAX_COUNTEROFFERS = 3;

    address public immutable arbitrator;
    uint256 public jobCount;

    struct Job {
        address client;
        address freelancer;
        string description;
        uint256 totalAmount;
        uint256 milestoneCount;
        uint256 counterofferCount;
        JobStatus status;
    }

    struct Milestone {
        string description;
        uint256 amount;
        uint256 durationDays;
        uint256 dueDate;
        uint256 submittedAt;
        uint256 revisionDeadline;
        uint256 revisionCount;
        MilestoneStatus status;
    }

    mapping(uint256 => Job) private jobs;
    mapping(uint256 => Milestone[]) private milestones;

    // Original terms are preserved so a rejected counteroffer
    // can return the job to the original proposal.
    mapping(uint256 => Milestone[]) private originalMilestones;
    mapping(uint256 => uint256) private originalTotalAmounts;

    event JobCreated(
        uint256 indexed jobId,
        address indexed client,
        address indexed freelancer,
        uint256 proposedAmount
    );

    event CounterofferSubmitted(
        uint256 indexed jobId,
        uint256 counterofferNumber,
        uint256 proposedAmount
    );

    event CounterofferAccepted(uint256 indexed jobId);
    event CounterofferRejected(uint256 indexed jobId);

    event JobAccepted(uint256 indexed jobId);
    event JobFunded(uint256 indexed jobId, uint256 amount);
    event JobCancelled(uint256 indexed jobId);

    event MilestoneSubmitted(
        uint256 indexed jobId,
        uint256 indexed milestoneId
    );

    event RevisionRequested(
        uint256 indexed jobId,
        uint256 indexed milestoneId,
        uint256 revisionCount
    );

    event DisputeRaised(
        uint256 indexed jobId,
        uint256 indexed milestoneId,
        address indexed raisedBy
    );

    event PaymentReleased(
        uint256 indexed jobId,
        uint256 indexed milestoneId,
        address indexed freelancer,
        uint256 amount
    );

    event DisputeResolved(
        uint256 indexed jobId,
        uint256 indexed milestoneId,
        uint256 freelancerAmount,
        uint256 clientRefund
    );

    event JobCompleted(uint256 indexed jobId);

    constructor() {
        arbitrator = msg.sender;
    }

    // 1. Client proposes a job without depositing funds.
    function createJob(
        address freelancer,
        string calldata description,
        string[] calldata milestoneDescriptions,
        uint256[] calldata milestoneAmounts,
        uint256[] calldata milestoneDurations
    ) external returns (uint256) {
        require(freelancer != address(0), "Invalid freelancer");
        require(freelancer != msg.sender, "Cannot hire yourself");
        require(bytes(description).length > 0, "Description required");

        uint256 count = milestoneAmounts.length;

        require(count > 0, "Add at least one milestone");
        require(
            milestoneDescriptions.length == count &&
                milestoneDurations.length == count,
            "Milestone arrays must match"
        );

        uint256 total = _validateMilestones(
            milestoneDescriptions,
            milestoneAmounts,
            milestoneDurations
        );

        jobCount++;
        uint256 jobId = jobCount;

        jobs[jobId] = Job({
            client: msg.sender,
            freelancer: freelancer,
            description: description,
            totalAmount: total,
            milestoneCount: count,
            counterofferCount: 0,
            status: JobStatus.Open
        });

        originalTotalAmounts[jobId] = total;

        for (uint256 i = 0; i < count; i++) {
            Milestone memory proposed = Milestone({
                description: milestoneDescriptions[i],
                amount: milestoneAmounts[i],
                durationDays: milestoneDurations[i],
                dueDate: 0,
                submittedAt: 0,
                revisionDeadline: 0,
                revisionCount: 0,
                status: MilestoneStatus.Pending
            });

            milestones[jobId].push(proposed);
            originalMilestones[jobId].push(proposed);
        }

        emit JobCreated(jobId, msg.sender, freelancer, total);
        return jobId;
    }

    // 2. Freelancer proposes revised milestone terms.
    // The original proposal remains saved for possible restoration.
    function submitCounteroffer(
        uint256 jobId,
        string[] calldata descriptions,
        uint256[] calldata amounts,
        uint256[] calldata durations
    ) external {
        Job storage job = _getJob(jobId);

        require(msg.sender == job.freelancer, "Only freelancer");
        require(job.status == JobStatus.Open, "Job not open");
        require(
            job.counterofferCount < MAX_COUNTEROFFERS,
            "Counteroffer limit reached"
        );

        uint256 total = _validateMilestones(
            descriptions,
            amounts,
            durations
        );

        delete milestones[jobId];

        for (uint256 i = 0; i < amounts.length; i++) {
            milestones[jobId].push(
                Milestone({
                    description: descriptions[i],
                    amount: amounts[i],
                    durationDays: durations[i],
                    dueDate: 0,
                    submittedAt: 0,
                    revisionDeadline: 0,
                    revisionCount: 0,
                    status: MilestoneStatus.Pending
                })
            );
        }

        job.totalAmount = total;
        job.milestoneCount = amounts.length;
        job.counterofferCount++;
        job.status = JobStatus.CounterOffered;

        emit CounterofferSubmitted(
            jobId,
            job.counterofferCount,
            total
        );
    }

    // 3. Client accepts the freelancer's counteroffer.
    // Freelancer must still confirm the revised agreement.
    function acceptCounteroffer(uint256 jobId) external {
        Job storage job = _getJob(jobId);

        require(msg.sender == job.client, "Only client");
        require(
            job.status == JobStatus.CounterOffered,
            "No counteroffer pending"
        );

        job.status = JobStatus.AwaitingFreelancerAcceptance;

        emit CounterofferAccepted(jobId);
    }

    // 4. Client rejects the counteroffer.
    // Restore the original milestone proposal.
    function rejectCounteroffer(uint256 jobId) external {
        Job storage job = _getJob(jobId);

        require(msg.sender == job.client, "Only client");
        require(
            job.status == JobStatus.CounterOffered,
            "No counteroffer pending"
        );

        delete milestones[jobId];

        for (uint256 i = 0; i < originalMilestones[jobId].length; i++) {
            milestones[jobId].push(originalMilestones[jobId][i]);
        }

        job.totalAmount = originalTotalAmounts[jobId];
        job.milestoneCount = originalMilestones[jobId].length;
        job.status = JobStatus.Open;

        emit CounterofferRejected(jobId);
    }

    // 5. Freelancer accepts the original offer or confirms
    // the counteroffer accepted by the client.
    function acceptJob(uint256 jobId) external {
        Job storage job = _getJob(jobId);

        require(msg.sender == job.freelancer, "Only freelancer");

        require(
            job.status == JobStatus.Open ||
                job.status == JobStatus.AwaitingFreelancerAcceptance,
            "Job not awaiting acceptance"
        );

        job.status = JobStatus.AwaitingFunding;

        emit JobAccepted(jobId);
    }

    // 6. Client funds the job after freelancer acceptance.
    function fundJob(uint256 jobId) external payable {
        Job storage job = _getJob(jobId);

        require(msg.sender == job.client, "Only client");
        require(
            job.status == JobStatus.AwaitingFunding,
            "Freelancer must accept first"
        );
        require(
            msg.value == job.totalAmount,
            "Deposit must equal agreed total"
        );

        job.status = JobStatus.Active;

        // Deadlines begin when escrow is funded.
        uint256 previousDueDate = block.timestamp;

        for (uint256 i = 0; i < job.milestoneCount; i++) {
            previousDueDate +=
                milestones[jobId][i].durationDays * 1 days;

            milestones[jobId][i].dueDate = previousDueDate;
        }

        emit JobFunded(jobId, msg.value);
    }

    // 7. Client cancels before funding.
    function cancelUnfundedJob(uint256 jobId) external {
        Job storage job = _getJob(jobId);

        require(msg.sender == job.client, "Only client");

        require(
            job.status == JobStatus.Open ||
                job.status == JobStatus.CounterOffered ||
                job.status == JobStatus.AwaitingFreelancerAcceptance ||
                job.status == JobStatus.AwaitingFunding,
            "Job cannot be cancelled"
        );

        job.status = JobStatus.Cancelled;

        emit JobCancelled(jobId);
    }

    // 8. Freelancer declines the original offer.
    function rejectJob(uint256 jobId) external {
        Job storage job = _getJob(jobId);

        require(msg.sender == job.freelancer, "Only freelancer");
        require(job.status == JobStatus.Open, "Original offer unavailable");

        job.status = JobStatus.Cancelled;

        emit JobCancelled(jobId);
    }

    // 9. Freelancer submits a milestone.
    function submitMilestone(
        uint256 jobId,
        uint256 milestoneId
    ) external {
        Job storage job = _getJob(jobId);

        require(msg.sender == job.freelancer, "Only freelancer");
        require(job.status == JobStatus.Active, "Job not active");
        require(milestoneId < job.milestoneCount, "Invalid milestone");

        Milestone storage milestone = milestones[jobId][milestoneId];

        if (milestone.status == MilestoneStatus.Pending) {
            require(
                block.timestamp <= milestone.dueDate,
                "Deadline passed; raise a dispute"
            );
        } else if (
            milestone.status == MilestoneStatus.RevisionRequested
        ) {
            require(
                block.timestamp <= milestone.revisionDeadline,
                "Revision deadline passed"
            );
        } else {
            revert("Milestone cannot be submitted");
        }

        milestone.status = MilestoneStatus.Submitted;
        milestone.submittedAt = block.timestamp;

        emit MilestoneSubmitted(jobId, milestoneId);
    }

    // 10. Client requests a revision.
    function requestRevision(
        uint256 jobId,
        uint256 milestoneId
    ) external {
        Job storage job = _getJob(jobId);

        require(msg.sender == job.client, "Only client");
        require(job.status == JobStatus.Active, "Job not active");
        require(milestoneId < job.milestoneCount, "Invalid milestone");

        Milestone storage milestone = milestones[jobId][milestoneId];

        require(
            milestone.status == MilestoneStatus.Submitted,
            "Milestone not submitted"
        );
        require(
            milestone.revisionCount < MAX_REVISIONS,
            "Revision limit reached"
        );

        milestone.revisionCount++;
        milestone.status = MilestoneStatus.RevisionRequested;
        milestone.revisionDeadline = block.timestamp + REVISION_PERIOD;

        emit RevisionRequested(
            jobId,
            milestoneId,
            milestone.revisionCount
        );
    }

    // 11. Client approves and pays a milestone.
    function approveMilestone(
        uint256 jobId,
        uint256 milestoneId
    ) external nonReentrant{
        Job storage job = _getJob(jobId);

        require(msg.sender == job.client, "Only client");
        require(job.status == JobStatus.Active, "Job not active");
        require(milestoneId < job.milestoneCount, "Invalid milestone");

        Milestone storage milestone = milestones[jobId][milestoneId];

        require(
            milestone.status == MilestoneStatus.Submitted,
            "Milestone not submitted"
        );

        uint256 amount = milestone.amount;
        milestone.status = MilestoneStatus.Paid;

        (bool success, ) = payable(job.freelancer).call{value: amount}("");
        require(success, "Payment failed");

        emit PaymentReleased(
            jobId,
            milestoneId,
            job.freelancer,
            amount
        );

        _tryCompleteJob(jobId);
    }

    // 12. Anyone can release payment after the review period.
    function finalizeUnchallengedMilestone(
        uint256 jobId,
        uint256 milestoneId
    ) external nonReentrant{
        Job storage job = _getJob(jobId);

        require(job.status == JobStatus.Active, "Job not active");
        require(milestoneId < job.milestoneCount, "Invalid milestone");

        Milestone storage milestone = milestones[jobId][milestoneId];

        require(
            milestone.status == MilestoneStatus.Submitted,
            "Milestone not submitted"
        );
        require(
            block.timestamp >= milestone.submittedAt + REVIEW_PERIOD,
            "Review period not over"
        );

        uint256 amount = milestone.amount;
        milestone.status = MilestoneStatus.Paid;

        (bool success, ) = payable(job.freelancer).call{value: amount}("");
        require(success, "Payment failed");

        emit PaymentReleased(
            jobId,
            milestoneId,
            job.freelancer,
            amount
        );

        _tryCompleteJob(jobId);
    }

    // 13. Client or freelancer raises a dispute.
    function raiseDispute(
        uint256 jobId,
        uint256 milestoneId
    ) external {
        Job storage job = _getJob(jobId);

        require(
            msg.sender == job.client || msg.sender == job.freelancer,
            "Not a party to this job"
        );
        require(job.status == JobStatus.Active, "Job not active");
        require(milestoneId < job.milestoneCount, "Invalid milestone");

        Milestone storage milestone = milestones[jobId][milestoneId];

        bool submitted =
            milestone.status == MilestoneStatus.Submitted;

        bool missedDeadline =
            milestone.status == MilestoneStatus.Pending &&
            block.timestamp > milestone.dueDate;

        bool missedRevisionDeadline =
            milestone.status == MilestoneStatus.RevisionRequested &&
            block.timestamp > milestone.revisionDeadline;

        bool freelancerChallengesRevision =
            milestone.status == MilestoneStatus.RevisionRequested &&
            msg.sender == job.freelancer;

        require(
            submitted ||
                missedDeadline ||
                missedRevisionDeadline ||
                freelancerChallengesRevision,
            "No dispute available"
        );

        milestone.status = MilestoneStatus.Disputed;

        emit DisputeRaised(jobId, milestoneId, msg.sender);
    }

    // 14. Arbitrator settles a disputed milestone.
    function resolveDispute(
        uint256 jobId,
        uint256 milestoneId,
        uint256 freelancerAmount
    ) external nonReentrant{
        require(msg.sender == arbitrator, "Only arbitrator");

        Job storage job = _getJob(jobId);

        require(job.status == JobStatus.Active, "Job not active");
        require(milestoneId < job.milestoneCount, "Invalid milestone");

        Milestone storage milestone = milestones[jobId][milestoneId];

        require(
            milestone.status == MilestoneStatus.Disputed,
            "Milestone not disputed"
        );
        require(
            freelancerAmount <= milestone.amount,
            "Settlement exceeds escrow"
        );

        uint256 clientRefund = milestone.amount - freelancerAmount;

        milestone.status = MilestoneStatus.Settled;

        if (freelancerAmount > 0) {
            (bool paid, ) = payable(job.freelancer).call{
                value: freelancerAmount
            }("");
            require(paid, "Freelancer payment failed");
        }

        if (clientRefund > 0) {
            (bool refunded, ) = payable(job.client).call{
                value: clientRefund
            }("");
            require(refunded, "Client refund failed");
        }

        emit DisputeResolved(
            jobId,
            milestoneId,
            freelancerAmount,
            clientRefund
        );

        _tryCompleteJob(jobId);
    }

    // 15. Read job details.
    function getJob(
        uint256 jobId
    )
        external
        view
        returns (
            address client,
            address freelancer,
            string memory description,
            uint256 totalAmount,
            uint256 milestoneCount,
            uint256 counterofferCount,
            JobStatus status
        )
    {
        Job storage job = _getJob(jobId);

        return (
            job.client,
            job.freelancer,
            job.description,
            job.totalAmount,
            job.milestoneCount,
            job.counterofferCount,
            job.status
        );
    }

    // 16. Read milestone details.
    function getMilestone(
        uint256 jobId,
        uint256 milestoneId
    )
        external
        view
        returns (
            string memory description,
            uint256 amount,
            uint256 durationDays,
            uint256 dueDate,
            uint256 submittedAt,
            uint256 revisionDeadline,
            uint256 revisionCount,
            MilestoneStatus status
        )
    {
        Job storage job = _getJob(jobId);

        require(milestoneId < job.milestoneCount, "Invalid milestone");

        Milestone storage milestone = milestones[jobId][milestoneId];

        return (
            milestone.description,
            milestone.amount,
            milestone.durationDays,
            milestone.dueDate,
            milestone.submittedAt,
            milestone.revisionDeadline,
            milestone.revisionCount,
            milestone.status
        );
    }

    // Validate a proposed set of milestones and calculate its total.
    function _validateMilestones(
        string[] calldata descriptions,
        uint256[] calldata amounts,
        uint256[] calldata durations
    ) internal pure returns (uint256 total) {
        uint256 count = amounts.length;

        require(count > 0, "Add at least one milestone");
        require(
            descriptions.length == count && durations.length == count,
            "Milestone arrays must match"
        );

        for (uint256 i = 0; i < count; i++) {
            require(
                bytes(descriptions[i]).length > 0,
                "Milestone description required"
            );
            require(amounts[i] > 0, "Amount must be positive");
            require(
                durations[i] > 0 && durations[i] <= 365,
                "Duration must be 1 to 365 days"
            );

            total += amounts[i];
        }
    }

    function _getJob(
        uint256 jobId
    ) internal view returns (Job storage job) {
        require(jobId > 0 && jobId <= jobCount, "Job does not exist");
        job = jobs[jobId];
    }

    function _tryCompleteJob(uint256 jobId) internal {
        Job storage job = jobs[jobId];

        for (uint256 i = 0; i < job.milestoneCount; i++) {
            MilestoneStatus status = milestones[jobId][i].status;

            if (
                status != MilestoneStatus.Paid &&
                status != MilestoneStatus.Settled
            ) {
                return;
            }
        }

        job.status = JobStatus.Completed;
        emit JobCompleted(jobId);
    }
}