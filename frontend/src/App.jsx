import React from 'react'
import './App.css'
import { useAppKit, useAppKitAccount } from '@reown/appkit/react'

const jobs = [
  {
    id: 1,
    title: "Website Designer for a Growing Startup",
    company: "BrightPath Studio",
    category: "Design & Creative",
    budget: "$800 - $1,500",
    type: "Fixed Price",
    level: "Intermediate",
    description:
      "Design a modern, responsive website with a clean interface and an excellent user experience.",
    skills: ["UI/UX Design", "Figma", "Web Design"],
    posted: "2 hours ago",
  },
  {
    id: 2,
    title: "React Developer for a Business Platform",
    company: "Nova Digital",
    category: "Development",
    budget: "$1,200 - $2,500",
    type: "Fixed Price",
    level: "Expert",
    description:
      "Build responsive React components and help improve an existing web application.",
    skills: ["React", "JavaScript", "CSS"],
    posted: "5 hours ago",
  },
  {
    id: 3,
    title: "Content Writer for a Technology Blog",
    company: "TechSphere Media",
    category: "Writing & Content",
    budget: "$150 - $400",
    type: "Fixed Price",
    level: "Entry Level",
    description:
      "Write clear, engaging articles about technology, digital innovation, and online business.",
    skills: ["Content Writing", "Research", "SEO"],
    posted: "1 day ago",
  },
  {
    id: 4,
    title: "Virtual Assistant for Business Operations",
    company: "PeakPoint Consulting",
    category: "Business & Admin",
    budget: "$300 - $700",
    type: "Fixed Price",
    level: "Intermediate",
    description:
      "Support daily operations through scheduling, email management, documentation, and research.",
    skills: ["Virtual Assistance", "Google Workspace", "Organization"],
    posted: "1 day ago",
  },
  {
    id: 5,
    title: "Social Media Manager for a Lifestyle Brand",
    company: "GreenLeaf Collective",
    category: "Marketing",
    budget: "$500 - $1,000",
    type: "Monthly",
    level: "Intermediate",
    description:
      "Plan social media content, schedule posts, and engage with an online community.",
    skills: ["Social Media", "Content Planning", "Canva"],
    posted: "2 days ago",
  },
  {
    id: 6,
    title: "Data Analyst for Market Research",
    company: "InsightWorks",
    category: "Data & Analytics",
    budget: "$600 - $1,200",
    type: "Fixed Price",
    level: "Intermediate",
    description:
      "Analyze research data and prepare clear reports to support business decisions.",
    skills: ["Excel", "Data Analysis", "Reporting"],
    posted: "3 days ago",
  },
]
function App() {
  const { open } = useAppKit()
  const { address, isConnected } = useAppKitAccount()
  const [search, setSearch] = React.useState('')
  const [category, setCategory] = React.useState('All Categories')
  const [page, setPage] = React.useState('home')
  const [currentUser, setCurrentUser] = React.useState(null)
  const [authMessage, setAuthMessage] = React.useState('')
  const [userRole, setUserRole] = React.useState('freelancer')
  const [applications, setApplications] = React.useState([])
  const [messages, setMessages] = React.useState([])
  const [postedJobs, setPostedJobs] = React.useState([])
  const [profile, setProfile] =React.useState({
    name: '',
    title: '',
    about: '',
    skills: '',
  })


  const filteredJobs = jobs.filter((job) => {
    const matchesSearch =
      job.title.toLowerCase().includes(search.toLowerCase()) ||
      job.description.toLowerCase().includes(search.toLowerCase()) ||
      job.skills.some((skill) =>
        skill.toLowerCase().includes(search.toLowerCase())
      )

    const matchesCategory =
      category === 'All Categories' || job.category === category

    return matchesSearch && matchesCategory
  })
  if (page === 'signup' || page === 'login') {
    return (
      <div className="auth-page">
        <div className="auth-card">
          <a href="#" className="logo" onClick={(e) => {
            e.preventDefault()
            setPage('home')
          }}>
            Trust<span>Lance</span>
          </a>

          <h1>{page === 'signup' ? 'Create your account' : 'Welcome back'}</h1>
          {authMessage && (
  <p role="alert" style={{ color: '#d93025', marginTop: '12px' }}>
    {authMessage}
  </p>
)}
          <p>
            {page === 'signup'
              ? 'Join TrustLance and start building trusted connections.'
              : 'Log in to continue to TrustLance.'}
          </p>

          {page === 'signup' && (
            <div className="form-group">
              <label>Full name</label>
              <input
  id="auth-name"
  type="text"
  placeholder="Enter your full name"
/>
            </div>
          )}

          <div className="form-group">
            <label>Email address</label>
            <input
  id="auth-email"
  type="email"
  placeholder="you@example.com"
/>
          </div>

          <div className="form-group">
            <label>Password</label>
            <input
  id="auth-password"
  type="password"
  placeholder="Enter your password"
/>
          </div>

          {page === 'signup' && (
            <div className="form-group">
              <label>I want to join as</label>
              <select
                id="auth-role"
                value={userRole}
                onChange={(e) => setUserRole(e.target.value)}
              >
                <option value="freelancer">Freelancer</option>
                <option value="client">Client</option>
              </select>
            </div>
          )}

          <button
  className="signup-btn auth-submit"
  onClick={() => {
    const name = document.getElementById('auth-name')?.value.trim()
    const email = document.getElementById('auth-email')?.value.trim().toLowerCase()
    const password = document.getElementById('auth-password')?.value
    const role = document.getElementById('auth-role')?.value || 'freelancer'

    if (!email || !password) {
      setAuthMessage('Please enter your email address and password.')
      return
    }

    const accounts = JSON.parse(localStorage.getItem('trustlanceAccounts') || '[]')

    if (page === 'signup') {
      if (!name) {
        setAuthMessage('Please enter your full name.')
        return
      }

      if (password.length < 8) {
        setAuthMessage('Your password must be at least 8 characters.')
        return
      }

      if (accounts.some((account) => account.email === email)) {
        setAuthMessage('An account with this email already exists. Please log in.')
        return
      }

      const account = { name, email, password, role }
      accounts.push(account)
      localStorage.setItem('trustlanceAccounts', JSON.stringify(accounts))

      setAuthMessage('Account created! You can now log in.')
      setPage('login')
      return
    }

    const account = accounts.find(
      (item) => item.email === email && item.password === password
    )

    if (!account) {
      setAuthMessage('Incorrect email or password. Please sign up first if you do not have an account.')
      return
    }

    setCurrentUser({
      name: account.name,
      email: account.email,
      role: account.role,
    })

    setUserRole(account.role)
    setAuthMessage('')
    setPage(account.role === 'client' ? 'client-dashboard' : 'freelancer-dashboard')
  }}
>
  {page === 'signup' ? 'Create Account' : 'Log In'}
</button>
          
          <button className="text-btn" onClick={() => setPage('home')}>
            ← Back to homepage
          </button>
        </div>
      </div>
    )
  }
  const dashboardPages = [
    'freelancer-dashboard',
    'client-dashboard',
    'find-jobs',
    'freelancer-profile',
    'post-job',
    'applications',
    'messaging',
    'notifications',
    'wallet',
  ]

  if (dashboardPages.includes(page)) {
    const pageTitles = {
      'freelancer-dashboard': 'Freelancer Dashboard',
      'client-dashboard': 'Client Dashboard',
      'find-jobs': 'Find Jobs',
      'freelancer-profile': 'Freelancer Profile',
      'post-job': 'Post a Job',
      applications: 'Applications',
      messaging: 'Messaging',
      notifications: 'Notifications',
      wallet: 'Wallet Connection',
    }

    return (

      <div className="dashboard-layout"> 
        <aside className="dashboard-sidebar">
          <a href="#" className="logo" onClick={(e) => {
            e.preventDefault()
            setPage('home')
          }}>
            Trust<span>Lance</span>
          </a>

          <p className="sidebar-label">WORKSPACE</p>

          {userRole === 'freelancer' && (
          <button onClick={() => setPage('freelancer-dashboard')}>
           Freelancer Dashboard
          </button>
          )}

          {userRole === 'client' && (
          <button onClick={() => setPage('client-dashboard')}>
           Client Dashboard
          </button>
              )}
          <button onClick={() => setPage('find-jobs')}>Find Jobs</button>
          <button onClick={() => setPage('freelancer-profile')}>
            Freelancer Profile
          </button>
          <button onClick={() => setPage('post-job')}>Post a Job</button>
          <button onClick={() => setPage('applications')}>
            Applications
          </button>
          <button onClick={() => setPage('messaging')}>Messaging</button>
          <button onClick={() => setPage('notifications')}>
            Notifications
          </button>
          <button onClick={() => setPage('wallet')}>Wallet Connection</button>

          <button className="sidebar-home" onClick={() => setPage('home')}>
            ← Back to Homepage
          </button>
        </aside>

        <main className="dashboard-main">
          <span className="eyebrow">TRUSTLANCE WORKSPACE</span>
          <h1>{pageTitles[page]}</h1>
          <div className="wallet-connect-area">
  <button
    className="wallet-connect-btn"
    onClick={() =>
      open({
        view: isConnected ? 'Account' : 'Connect',
      })
    }
  >
    {isConnected && address
      ? `${address.slice(0, 6)}...${address.slice(-4)}`
      : 'Connect Wallet'}
  </button>

  <p className="wallet-status">
    {isConnected
      ? 'Wallet connected successfully'
      : 'Connect MetaMask or another compatible wallet'}
  </p>
</div>

          {page === 'freelancer-profile' && (
  <section className="dashboard-panel">
    <h2>My Professional Profile</h2>
    <p>Show clients your experience, expertise, and skills.</p>

    <label>Full Name</label>
    <input
      value={profile.name}
      onChange={(e) =>
        setProfile({ ...profile, name: e.target.value })
      }
      placeholder="Your full name"
    />

    <label>Professional Title</label>
    <input
      value={profile.title}
      onChange={(e) =>
        setProfile({ ...profile, title: e.target.value })
      }
      placeholder="e.g. Web Developer"
    />

    <label>About You</label>
    <textarea
      value={profile.about}
      onChange={(e) =>
        setProfile({ ...profile, about: e.target.value })
      }
      placeholder="Describe your skills and experience"
      rows="5"
    />

    <label>Skills</label>
    <input
      value={profile.skills}
      onChange={(e) =>
        setProfile({ ...profile, skills: e.target.value })
      }
      placeholder="e.g. React, Design, Writing"
    />

    <button onClick={() => alert('Profile saved for this session!')}>
      Save Profile
    </button>

    <div className="profile-preview">
      <h3>Profile Preview</h3>
      <h4>{profile.name || 'Your Name'}</h4>
      <p>{profile.title || 'Your Professional Title'}</p>
      <p>{profile.about || 'Your introduction will appear here.'}</p>
      <strong>Skills:</strong>
      <p>{profile.skills || 'Your skills will appear here.'}</p>
    </div>
  </section>
)}
          
          {page === 'client-dashboard' && (
  <section className="dashboard-panel">
    <h2>
      Welcome{currentUser?.name ? ', ' + currentUser.name : ', Client'}!
    </h2>

    <p>
      Manage your projects, publish job opportunities, and connect
      with talented freelancers on TrustLance.
    </p>

    <div className="dashboard-stats">
      <div>
        <strong>{postedJobs.length}</strong>
        <span>Jobs Posted This Session</span>
      </div>

      <div>
        <strong>{applications.length}</strong>
        <span>Applications Submitted</span>
      </div>

      <div>
        <strong>0</strong>
        <span>Projects Completed</span>
      </div>
    </div>

    <h3>Quick Actions</h3>

    <button onClick={() => setPage('post-job')}>
      Post a Job
    </button>

    <button onClick={() => setPage('applications')}>
      View Applications
    </button>

    <button onClick={() => setPage('messaging')}>
      Open Messages
    </button>

    <button onClick={() => setPage('notifications')}>
      Notifications
    </button>

    <button onClick={() => setPage('wallet')}>
      Wallet Connection
    </button>
  </section>
)}
    
          {page === 'freelancer-dashboard' && (
            <section className="dashboard-panel">
              <h2>
                Welcome{currentUser?.name ? ', ' + currentUser.name : ', Freelancer'}!
              </h2>

              <p>
                Find opportunities, manage your applications, and grow your freelance career.
              </p>

              <div className="dashboard-stats">
                <div>
                  <strong>{applications.length}</strong>
                  <span>Applications Submitted</span>
                </div>

                <div>
                  <strong>{postedJobs.length}</strong>
                  <span>Available Job Posts</span>
                </div>

                <div>
                  <strong>0</strong>
                  <span>Completed Projects</span>
                </div>
              </div>

              <button onClick={() => setPage('find-jobs')}>
                Explore Jobs
              </button>

              <button onClick={() => setPage('applications')}>
                My Applications
              </button>

              <button onClick={() => setPage('freelancer-profile')}>
                My Profile
              </button>

              <button onClick={() => setPage('notifications')}>
                Notifications
              </button>

              <button onClick={() => setPage('wallet')}>
                Connect Wallet
              </button>
            </section>
          )}

          {page === 'find-jobs' && (
            <section className="dashboard-panel">
              <input
                placeholder="Search jobs or skills..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
              <select value={category} onChange={(e) => setCategory(e.target.value)}>
                <option>All Categories</option>
                <option>Design & Creative</option>
                <option>Development</option>
                <option>Writing & Content</option>
                <option>Business & Admin</option>
                <option>Marketing</option>
                <option>Data & Analytics</option>
              </select>

              {[...filteredJobs, ...postedJobs].map((job) => (
                <article className="dashboard-panel" key={job.id}>
                  <h3>{job.title}</h3>
                  <p>{job.company} · {job.category}</p>
                  <p>{job.description}</p>
                  <strong>{job.budget}</strong>
                  <button
  onClick={() => {
    const alreadyApplied = applications.some(
      (application) => application.id === job.id
    )

    if (alreadyApplied) {
      alert('You have already applied for this job.')
      return
    }

    setApplications([...applications, job])
    alert('Your application has been submitted!')
  }}
>
  Apply for Job
                  </button>
                </article>
              ))}
            </section>
          )}

          {page === 'freelancer-profile' && (
            <section className="dashboard-panel">
              <label>Full Name</label>
              <input placeholder="Your name" />
              <label>Professional Title</label>
              <input placeholder="e.g. Web Developer" />
              <label>About You</label>
              <textarea placeholder="Describe your skills and experience" />
              <label>Skills</label>
              <input placeholder="e.g. React, Design, Writing" />
              <button onClick={() => alert('Profile demo: saving will be connected later.')}>
                Save Profile
              </button>
            </section>
          )}

          {page === 'post-job' && (
            <section className="dashboard-panel">
              <label>Job Title</label>
              <input id="new-job-title" placeholder="Enter the job title" />
              <label>Job Description</label>
              <textarea id="new-job-description" placeholder="Describe the project and responsibilities" />
              <label>Category</label>
<select id="new-job-category">
  <option>Development</option>
  <option>Design & Creative</option>
  <option>Writing & Content</option>
  <option>Business & Admin</option>
  <option>Marketing</option>
  <option>Data & Analytics</option>
</select>
              <label>Budget</label>
              <input id="new-job-budget" placeholder="e.g. $500 - $1,000" />
              <button
  onClick={() => {
    const title = document.getElementById('new-job-title').value.trim()
    const description = document.getElementById('new-job-description').value.trim()
    const budget = document.getElementById('new-job-budget').value.trim()
    const categoryValue = document.getElementById('new-job-category').value

    if (!title || !description || !budget) {
      alert('Please complete the job title, description, and budget.')
      return
    }

    const newJob = {
      id: Date.now(),
      title,
      description,
      budget,
      category: categoryValue,
      company: 'TrustLance Client',
      type: 'Fixed Price',
      level: 'Intermediate',
      skills: [],
      posted: 'Just now',
    }

    setPostedJobs([...postedJobs, newJob])
    alert('Job published successfully!')
    setPage('find-jobs')
  }}
>
  Publish Job
</button>
            </section>
          )}

          {page === 'applications' && (
  <section className="dashboard-panel">
    <h2>My Applications</h2>

    {applications.length === 0 ? (
      <p>No applications yet. Visit Find Jobs to apply for a project.</p>
    ) : (
      applications.map((job) => (
        <article className="dashboard-panel" key={job.id}>
          <h3>{job.title}</h3>
          <p>{job.company}</p>
          <p>Budget: {job.budget}</p>
          <p>Status: Application submitted</p>
        </article>
      ))
    )}

    <button onClick={() => setPage('find-jobs')}>
      Find More Jobs
    </button>
  </section>
)}

          {page === 'messaging' && (
  <section className="dashboard-panel">
    <h2>Messages</h2>
    <p>Communicate with clients and freelancers on TrustLance.</p>

    <div className="message-list">
      {messages.length === 0 ? (
        <p>No messages yet. Send your first message below.</p>
      ) : (
        messages.map((message) => (
          <div className="message-item" key={message.id}>
            <p>{message.text}</p>
            <small>{message.time}</small>
          </div>
        ))
      )}
    </div>

    <form
      onSubmit={(e) => {
        e.preventDefault();

        const input = e.target.elements.message;
        const text = input.value.trim();

        if (!text) return;

        setMessages([
          ...messages,
          {
            id: Date.now(),
            text,
            time: new Date().toLocaleTimeString(),
          },
        ]);

        input.value = '';
      }}
    >
      <input
        name="message"
        placeholder="Type your message..."
        aria-label="Type your message"
      />
      <button type="submit">Send Message</button>
    </form>
  </section>
)}

          {page === 'notifications' && (
            <section className="dashboard-panel">
              <h2>Notifications</h2>
              <p>You have no new notifications.</p>
            </section>
          )}

          {page === 'wallet' && (
  <section className="dashboard-panel">
    <h2>Connect Your Wallet</h2>

    <p>
      Connect a compatible Web3 wallet to access wallet features.
    </p>

    <button
      className="wallet-connect-btn"
      onClick={() =>
        open({
          view: isConnected ? 'Account' : 'Connect',
        })
      }
    >
      {isConnected
        ? `${address.slice(0, 6)}...${address.slice(-4)}`
        : 'Connect Wallet'}
    </button>

    <p className="wallet-status">
      {isConnected
        ? 'Wallet connected successfully'
        : 'Connect MetaMask or another compatible wallet'}
    </p>
  </section>
)}
</main>
</div>
    )
  }
  return (
    <div className="app">
      <nav className="navbar">
        <a href="/" className="logo">
          Trust<span>Lance</span>
        </a>

        <div className="nav-links">
  <a
    href="#find-work"
    onClick={(e) => {
      e.preventDefault()
      setPage('find-jobs')
    }}
  >
    Find Work
  </a>

  <a
    href="#find-talent"
    onClick={(e) => {
      e.preventDefault()
      setPage('client-dashboard')
    }}
  >
    Find Talent
  </a>

  <a href="#how-it-works">How It Works</a>
</div>

        <div className="nav-actions">
  <button
    className="login-btn"
    onClick={() => setPage('login')}
  >
    Log In
  </button>

  <button
    className="signup-btn"
    onClick={() => setPage('signup')}
  >
    Get Started
  </button>
</div>
      </nav>

      <main>
        <section className="hero">
          <div className="hero-content">
            <span className="eyebrow">FREELANCING, REIMAGINED</span>

            <h1>
              Great work deserves
              <br />
              <span>trusted payments.</span>
            </h1>

            <p>
              Connect with talented professionals, collaborate with confidence,
              and manage project milestones in one place.
            </p>

            <div className="hero-actions">
              <a href="#find-work" className="primary-btn">
                Find Work <span>→</span>
              </a>
              <a href="#find-talent" className="secondary-btn">
                Hire Talent
              </a>
            </div>

            <div className="trust-note">
              <span className="trust-dot"></span>
              Built for transparency, accountability, and trust.
            </div>
          </div>

          <div className="hero-card">
            <div className="card-top">
              <div>
                <span className="small-label">PROJECT OVERVIEW</span>
                <h3>Website Redesign</h3>
              </div>
              <span className="status-badge">In progress</span>
            </div>

            <div className="payment-box">
              <span>Project budget</span>
              <h2>$2,400.00</h2>
              <span className="muted-text">
                Illustrative project data
              </span>
            </div>

            <div className="milestone-heading">
              <strong>Project milestones</strong>
              <span>2 of 3</span>
            </div>

            <div className="milestone">
              <span className="milestone-icon completed">✓</span>
              <div className="milestone-info">
                <strong>Project discovery</strong>
                <span>Completed</span>
              </div>
              <span className="milestone-check">✓</span>
            </div>

            <div className="milestone">
              <span className="milestone-icon completed">✓</span>
              <div className="milestone-info">
                <strong>Design and prototype</strong>
                <span>Completed</span>
              </div>
              <span className="milestone-check">✓</span>
            </div>

            <div className="milestone">
              <span className="milestone-icon pending">3</span>
              <div className="milestone-info">
                <strong>Final delivery</strong>
                <span>Awaiting completion</span>
              </div>
            </div>

            <div className="security-note">
              <span>◇</span>
              <p>
                <strong>Milestone transparency</strong>
                <br />
                Track project progress in one place.
              </p>
            </div>
          </div>
        </section>
        
        <section className="categories" id="find-work">
          <div className="section-heading">
            <div>
              <span className="eyebrow">EXPLORE OPPORTUNITIES</span>
              <h2>Find work that fits your skills.</h2>
            </div>
            <a href="#find-work">Explore categories →</a>
          </div>

          <div className="category-grid">
            <article className="category-card">
              <span className="category-icon">✳️</span>
              <h3>Design & Creative</h3>
              <p>Branding, graphics, and digital experiences.</p>
            </article>

            <article className="category-card">
              <span className="category-icon">⌘</span>
              <h3>Development</h3>
              <p>Websites, applications, and software.</p>
            </article>

            <article className="category-card">
              <span className="category-icon">▤</span>
              <h3>Writing & Content</h3>
              <p>Articles, copywriting, and content strategy.</p>
            </article>

            <article className="category-card">
              <span className="category-icon">◈</span>
              <h3>Business & Admin</h3>
              <p>Virtual assistance, research, and operations.</p>
            </article>
          </div>
        </section>

        <section className="how-section" id="how-it-works">
          <span className="eyebrow">SIMPLE BY DESIGN</span>
          <h2>Work together with confidence.</h2>
          <p>
            Clear agreements, visible milestones, and transparent project
            progress help clients and freelancers work better together.
          </p>

          <div className="how-grid">
            <div>
              <span>01</span>
              <h3>Find your match</h3>
              <p>Connect with clients or freelancers for your next project.</p>
            </div>
            <div>
              <span>02</span>
              <h3>Agree on milestones</h3>
              <p>Set expectations, deliverables, and project stages.</p>
            </div>
            <div>
              <span>03</span>
              <h3>Track your progress</h3>
              <p>Keep project updates and milestone status organised.</p>
            </div>
          </div>
        </section>

        <section className="cta-section" id="find-talent">
          <div>
            <span className="eyebrow">YOUR NEXT PROJECT STARTS HERE</span>
            <h2>Good work begins with trust.</h2>
            <p>Find opportunities or discover talent for your next idea.</p>
          </div>
          <button className="signup-btn" onClick={() => setPage('signup')}>Get Started →</button>
        </section>
      </main>
      
      <footer className="footer">
        <a href="/" className="logo">
          Trust<span>Lance</span>
        </a>
        <p>Connecting talent. Building trust.</p>
        <span>© 2026 TrustLance</span>
      </footer>
    </div>
  )
  }
export default App