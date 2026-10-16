// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {TrustLance} from "../src/TrustLance.sol";

contract TrustLanceTest is Test {
    TrustLance trustLance;

    address client = address(0xBEEF);
    address freelancer = address(0xCAFE);
    address stranger = address(0x1234);

    function setUp() public {
        trustLance = new TrustLance();

        vm.deal(client, 20 ether);
        vm.deal(freelancer, 5 ether);
        vm.deal(stranger, 5 ether);
    }

    function createSampleJob() internal returns (uint256) {
        string[] memory descriptions = new string[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory durations = new uint256[](2);

        descriptions[0] = "Design the website";
        descriptions[1] = "Complete the website";

        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        durations[0] = 7;
        durations[1] = 14;

        vm.prank(client);

        return trustLance.createJob(
            freelancer,
            "Build a freelance marketplace",
            descriptions,
            amounts,
            durations
        );
    }

    function testClientCanCreateJobWithoutDepositing() public {
        uint256 jobId = createSampleJob();

        (
            address jobClient,
            address jobFreelancer,
            ,
            uint256 totalAmount,
            uint256 milestoneCount,
            ,
            TrustLance.JobStatus status
        ) = trustLance.getJob(jobId);

        assertEq(jobClient, client);
        assertEq(jobFreelancer, freelancer);
        assertEq(totalAmount, 3 ether);
        assertEq(milestoneCount, 2);
        assertEq(
            uint256(status),
            uint256(TrustLance.JobStatus.Open)
        );

        assertEq(address(trustLance).balance, 0);
    }

    function testFreelancerCanSubmitCounteroffer() public {
        uint256 jobId = createSampleJob();

        string[] memory descriptions = new string[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory durations = new uint256[](2);

        descriptions[0] = "Design and build the homepage";
        descriptions[1] = "Complete and test the website";

        amounts[0] = 2 ether;
        amounts[1] = 3 ether;

        durations[0] = 10;
        durations[1] = 20;

        vm.prank(freelancer);

        trustLance.submitCounteroffer(
            jobId,
            descriptions,
            amounts,
            durations
        );

        (
            ,
            ,
            ,
            uint256 totalAmount,
            ,
            uint256 counterofferCount,
            TrustLance.JobStatus status
        ) = trustLance.getJob(jobId);

        assertEq(totalAmount, 5 ether);
        assertEq(counterofferCount, 1);
        assertEq(
            uint256(status),
            uint256(TrustLance.JobStatus.CounterOffered)
        );
    }

    function testClientCanAcceptCounterofferAndFreelancerCanConfirm() public {
        uint256 jobId = createSampleJob();

        string[] memory descriptions = new string[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory durations = new uint256[](2);

        descriptions[0] = "Design the website";
        descriptions[1] = "Finish and test the website";

        amounts[0] = 2 ether;
        amounts[1] = 3 ether;

        durations[0] = 10;
        durations[1] = 20;

        vm.prank(freelancer);
        trustLance.submitCounteroffer(
            jobId,
            descriptions,
            amounts,
            durations
        );

        vm.prank(client);
        trustLance.acceptCounteroffer(jobId);

        vm.prank(freelancer);
        trustLance.acceptJob(jobId);

        (
            ,
            ,
            ,
            uint256 totalAmount,
            ,
            ,
            TrustLance.JobStatus status
        ) = trustLance.getJob(jobId);

        assertEq(totalAmount, 5 ether);
        assertEq(
            uint256(status),
            uint256(TrustLance.JobStatus.AwaitingFunding)
        );

        // The client has not deposited the escrow money yet.
        assertEq(address(trustLance).balance, 0);
    }

    function testClientCanFundAfterFreelancerAccepts() public {
        uint256 jobId = createSampleJob();

        vm.prank(freelancer);
        trustLance.acceptJob(jobId);

        vm.prank(client);
        trustLance.fundJob{value: 3 ether}(jobId);

        (
            ,
            ,
            ,
            uint256 totalAmount,
            ,
            ,
            TrustLance.JobStatus status
        ) = trustLance.getJob(jobId);

        assertEq(totalAmount, 3 ether);
        assertEq(
            uint256(status),
            uint256(TrustLance.JobStatus.Active)
        );

        assertEq(address(trustLance).balance, 3 ether);
    }

    function testFundingWithWrongAmountReverts() public {
        uint256 jobId = createSampleJob();

        vm.prank(freelancer);
        trustLance.acceptJob(jobId);

        vm.expectRevert();

        vm.prank(client);
        trustLance.fundJob{value: 2 ether}(jobId);
    }

    function testStrangerCannotAcceptAnotherFreelancersJob() public {
        uint256 jobId = createSampleJob();

        vm.expectRevert();

        vm.prank(stranger);
        trustLance.acceptJob(jobId);
    }
   
function testFreelancerCanSubmitFirstMilestone() public {
        uint256 jobId = createSampleJob();

        vm.prank(freelancer);
        trustLance.acceptJob(jobId);

        vm.prank(client);
        trustLance.fundJob{value: 3 ether}(jobId);

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            TrustLance.MilestoneStatus status
        ) = trustLance.getMilestone(jobId, 0);

        assertEq(
            uint256(status),
            uint256(TrustLance.MilestoneStatus.Submitted)
        );
    }

    function testClientCanRequestMilestoneRevision() public {
        uint256 jobId = createSampleJob();

        vm.prank(freelancer);
        trustLance.acceptJob(jobId);

        vm.prank(client);
        trustLance.fundJob{value: 3 ether}(jobId);

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        vm.prank(client);
        trustLance.requestRevision(jobId, 0);

        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            TrustLance.MilestoneStatus status
        ) = trustLance.getMilestone(jobId, 0);

        assertEq(
            uint256(status),
            uint256(TrustLance.MilestoneStatus.RevisionRequested)
        );
    }

    function testFreelancerCanResubmitAfterRevision() public {
        uint256 jobId = createSampleJob();

        vm.prank(freelancer);
        trustLance.acceptJob(jobId);

        vm.prank(client);
        trustLance.fundJob{value: 3 ether}(jobId);

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        vm.prank(client);
        trustLance.requestRevision(jobId, 0);

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            TrustLance.MilestoneStatus status
        ) = trustLance.getMilestone(jobId, 0);

        assertEq(
            uint256(status),
            uint256(TrustLance.MilestoneStatus.Submitted)
        );
    }

    function testClientApprovalPaysFreelancer() public {
        uint256 jobId = createSampleJob();

        vm.prank(freelancer);
        trustLance.acceptJob(jobId);

        vm.prank(client);
        trustLance.fundJob{value: 3 ether}(jobId);

        uint256 freelancerBalanceBefore = freelancer.balance;

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        vm.prank(client);
        trustLance.approveMilestone(jobId, 0);

        assertEq(
            freelancer.balance,
            freelancerBalanceBefore + 1 ether
        );

        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            TrustLance.MilestoneStatus status
        ) = trustLance.getMilestone(jobId, 0);

        assertEq(
            uint256(status),
            uint256(TrustLance.MilestoneStatus.Paid)
        );
    }

    function testJobCompletesAfterAllMilestonesArePaid() public {
        uint256 jobId = createSampleJob();

        vm.prank(freelancer);
        trustLance.acceptJob(jobId);

        vm.prank(client);
        trustLance.fundJob{value: 3 ether}(jobId);

        // Submit and approve the first milestone.
        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        vm.prank(client);
        trustLance.approveMilestone(jobId, 0);

        // Submit and approve the second milestone.
        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 1);

        vm.prank(client);
        trustLance.approveMilestone(jobId, 1);

        (
            ,
            ,
            ,
            ,
            ,
            ,
            TrustLance.JobStatus status
        ) = trustLance.getJob(jobId);

        assertEq(
            uint256(status),
            uint256(TrustLance.JobStatus.Completed)
        );

        assertEq(address(trustLance).balance, 0);
    }
}
contract TrustLanceCounterofferExtraTest is Test {
    TrustLance trustLance;

    address client = address(0xBEEF);
    address freelancer = address(0xCAFE);

    function setUp() public {
        trustLance = new TrustLance();

        vm.deal(client, 20 ether);
        vm.deal(freelancer, 5 ether);
    }

    function createSampleJob() internal returns (uint256) {
        string[] memory descriptions = new string[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory durations = new uint256[](2);

        descriptions[0] = "Design the website";
        descriptions[1] = "Complete the website";

        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        durations[0] = 7;
        durations[1] = 14;

        vm.prank(client);
        return trustLance.createJob(
            freelancer,
            "Build a freelance marketplace",
            descriptions,
            amounts,
            durations
        );
    }

    function submitCounteroffer(uint256 jobId, uint256 firstAmount) internal {
        string[] memory descriptions = new string[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory durations = new uint256[](2);

        descriptions[0] = "Revised website design";
        descriptions[1] = "Revised website completion";

        amounts[0] = firstAmount;
        amounts[1] = 2 ether;

        durations[0] = 10;
        durations[1] = 14;

        vm.prank(freelancer);
        trustLance.submitCounteroffer(
            jobId,
            descriptions,
            amounts,
            durations
        );
    }

    function testRejectingCounterofferRestoresOriginalTerms() public {
        uint256 jobId = createSampleJob();

        submitCounteroffer(jobId, 2 ether);

        vm.prank(client);
        trustLance.rejectCounteroffer(jobId);

        (
            ,
            ,
            ,
            uint256 totalAmount,
            ,
            ,
            TrustLance.JobStatus status
        ) = trustLance.getJob(jobId);

        assertEq(totalAmount, 3 ether);
        assertEq(
            uint256(status),
            uint256(TrustLance.JobStatus.Open)
        );

        (
            string memory firstDescription,
            uint256 firstAmount,
            uint256 firstDuration,
            ,
            ,
            ,
            ,
            TrustLance.MilestoneStatus firstStatus
        ) = trustLance.getMilestone(jobId, 0);

        assertEq(firstDescription, "Design the website");
        assertEq(firstAmount, 1 ether);
        assertEq(firstDuration, 7);
        assertEq(
            uint256(firstStatus),
            uint256(TrustLance.MilestoneStatus.Pending)
        );
    }

    function testCannotSubmitFourthCounteroffer() public {
        uint256 jobId = createSampleJob();

        for (uint256 i = 0; i < 3; i++) {
            submitCounteroffer(jobId, (i + 2) * 1 ether);

            vm.prank(client);
            trustLance.rejectCounteroffer(jobId);
        }

        vm.expectRevert();

        submitCounteroffer(jobId, 5 ether);
    }
} 
contract TrustLanceSecurityTest is Test {
    TrustLance trustLance;

    address client = address(0xBEEF);
    address freelancer = address(0xCAFE);
    address stranger = address(0x1234);

    function setUp() public {
        trustLance = new TrustLance();

        vm.deal(client, 20 ether);
        vm.deal(freelancer, 5 ether);
        vm.deal(stranger, 5 ether);
    }

    function createSampleJob() internal returns (uint256) {
        string[] memory descriptions = new string[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory durations = new uint256[](2);

        descriptions[0] = "Design the website";
        descriptions[1] = "Complete the website";

        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        durations[0] = 7;
        durations[1] = 14;

        vm.prank(client);

        return trustLance.createJob(
            freelancer,
            "Build a freelance marketplace",
            descriptions,
            amounts,
            durations
        );
    }

    function fundSampleJob() internal returns (uint256 jobId) {
        jobId = createSampleJob();

        vm.prank(freelancer);
        trustLance.acceptJob(jobId);

        vm.prank(client);
        trustLance.fundJob{value: 3 ether}(jobId);
    }

    // TEST 1: Resolve a dispute and refund the client correctly.
    function testDisputeResolutionPaysFreelancerAndRefundsClient()
        public
    {
        uint256 jobId = fundSampleJob();

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        vm.prank(client);
        trustLance.raiseDispute(jobId, 0);

        uint256 clientBalanceBefore = client.balance;
        uint256 freelancerBalanceBefore = freelancer.balance;

        // Arbitrator resolves the dispute.
        // The test contract is the arbitrator because it deployed TrustLance.
        trustLance.resolveDispute(jobId, 0, 0.4 ether);

        assertEq(client.balance, clientBalanceBefore + 0.6 ether);
        assertEq(
            freelancer.balance,
            freelancerBalanceBefore + 0.4 ether
        );

        (
            ,,,,,,,
            TrustLance.MilestoneStatus status
        ) = trustLance.getMilestone(jobId, 0);

        assertEq(
            uint256(status),
            uint256(TrustLance.MilestoneStatus.Settled)
        );
    }

    // TEST 2: An unauthorized address cannot resolve a dispute.
    function testStrangerCannotResolveDispute() public {
        uint256 jobId = fundSampleJob();

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        vm.prank(client);
        trustLance.raiseDispute(jobId, 0);

        vm.expectRevert();
        vm.prank(stranger);
        trustLance.resolveDispute(jobId, 0, 0.4 ether);
    }

    // TEST 3: A freelancer cannot submit a milestone after its deadline.
    function testFreelancerCannotSubmitMilestoneAfterDeadline()
        public
    {
        uint256 jobId = fundSampleJob();

        // The first milestone has a seven-day duration.
        vm.warp(block.timestamp + 8 days);

        vm.expectRevert();
        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);
    }

    // TEST 4: A client can raise a dispute after the revision deadline.
    function testClientCanRaiseDisputeAfterRevisionDeadline()
        public
    {
        uint256 jobId = fundSampleJob();

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        vm.prank(client);
        trustLance.requestRevision(jobId, 0);

        // Revision period is three days.
        vm.warp(block.timestamp + 4 days);

        vm.prank(client);
        trustLance.raiseDispute(jobId, 0);

        (
            ,,,,,,,
            TrustLance.MilestoneStatus status
        ) = trustLance.getMilestone(jobId, 0);

        assertEq(
            uint256(status),
            uint256(TrustLance.MilestoneStatus.Disputed)
        );
    }

    // TEST 5: A stranger cannot submit a milestone for the freelancer.
    function testStrangerCannotSubmitMilestone() public {
        uint256 jobId = fundSampleJob();

        vm.expectRevert();
        vm.prank(stranger);
        trustLance.submitMilestone(jobId, 0);
    }
}
contract TrustLancePaymentSecurityTest is Test {
    TrustLance trustLance;

    address client = address(0xBEEF);
    address freelancer = address(0xCAFE);
    address stranger = address(0x1234);

    function setUp() public {
        trustLance = new TrustLance();

        vm.deal(client, 20 ether);
        vm.deal(freelancer, 5 ether);
        vm.deal(stranger, 5 ether);
    }

    function createFundedJob() internal returns (uint256 jobId) {
        string[] memory descriptions = new string[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory durations = new uint256[](2);

        descriptions[0] = "Design the website";
        descriptions[1] = "Complete the website";

        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        durations[0] = 7;
        durations[1] = 14;

        vm.prank(client);
        jobId = trustLance.createJob(
            freelancer,
            "Build a freelance marketplace",
            descriptions,
            amounts,
            durations
        );

        vm.prank(freelancer);
        trustLance.acceptJob(jobId);

        vm.prank(client);
        trustLance.fundJob{value: 3 ether}(jobId);
    }

    // TEST 19: A paid milestone cannot be paid twice.
    function testCannotApproveAlreadyPaidMilestone() public {
        uint256 jobId = createFundedJob();

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        vm.prank(client);
        trustLance.approveMilestone(jobId, 0);

        uint256 freelancerBalanceAfterFirstPayment =
            freelancer.balance;

        vm.expectRevert(bytes("Milestone not submitted"));
        vm.prank(client);
        trustLance.approveMilestone(jobId, 0);

        assertEq(
            freelancer.balance,
            freelancerBalanceAfterFirstPayment
        );
    }

    // TEST 20: An arbitrator cannot award more than the milestone amount.
    function testCannotResolveDisputeAboveMilestoneAmount() public {
        uint256 jobId = createFundedJob();

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        vm.prank(client);
        trustLance.raiseDispute(jobId, 0);

        vm.expectRevert(bytes("Settlement exceeds escrow"));
        trustLance.resolveDispute(jobId, 0, 2 ether);
    }

    // TEST 21: A stranger cannot approve a freelancer's milestone.
    function testStrangerCannotApproveMilestone() public {
        uint256 jobId = createFundedJob();

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        vm.expectRevert(bytes("Only client"));
        vm.prank(stranger);
        trustLance.approveMilestone(jobId, 0);
    }

    // TEST 22: Automatic finalization cannot pay an already-paid milestone.
    function testCannotFinalizeAlreadyPaidMilestone() public {
        uint256 jobId = createFundedJob();

        vm.prank(freelancer);
        trustLance.submitMilestone(jobId, 0);

        vm.prank(client);
        trustLance.approveMilestone(jobId, 0);

        uint256 freelancerBalanceAfterApproval = freelancer.balance;

        // Move time beyond the review period.
        vm.warp(block.timestamp + 6 days);

        vm.expectRevert(bytes("Milestone not submitted"));
        trustLance.finalizeUnchallengedMilestone(jobId, 0);

        assertEq(
            freelancer.balance,
            freelancerBalanceAfterApproval
        );
    }
}