# Work Time Stat — Enterprise Employee Activity & Working Time Analytics

<div align="center">

<img src="assets/logo.png" alt="Work Time Stat Logo" width="360" />

<br/><br/>

![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011%20%7C%20Windows%20Server-0078D4?logo=windows&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-x64%20%7C%20x86-blue)
![Deployment](https://img.shields.io/badge/Deployment-Custom%20Administrative%20Rollout-orange)
![Security](https://img.shields.io/badge/Privacy-Non--Intrusive%20Telemetry-success)
![Status](https://img.shields.io/badge/License-Commercial%20%2F%20Custom%20Quotation-brightgreen)

<br/>

**A customizable employee computer activity monitoring and working time analytics solution designed for businesses.**

</div>

---

## 📌 Executive Overview

**Work Time Stat** is a customizable employee computer activity monitoring and working time analytics solution designed for businesses. The platform provides detailed insights into computer usage, application activity, working patterns, and productivity-related statistics.

Each deployment is individually configured and installed by an administrator according to the customer's infrastructure, operational requirements, and security policies.

Unlike off-the-shelf intrusive surveillance tools, **Work Time Stat** prioritizes **operational clarity, privacy compliance, and system efficiency**. It operates with ultra-low resource utilization (<0.1% CPU), requires zero workstation user interaction, and collects actionable operational data without invasive keylogging or screen recording.

---

## 🧭 Navigation & Documentation

- [📋 Comprehensive Features & Capabilities](FEATURES.md)
- [🏗️ Technical Architecture & System Overview](TECHNICAL_OVERVIEW.md)
- [⚙️ Deployment Model & Installation Procedures](INSTALLATION.md)
- [💼 Commercial Model & Custom Pricing](PRICING.md)
- [🛡️ Security Architecture & Privacy Safeguards](SECURITY.md)

---

## 🚀 Key Capabilities

- **Automated Working Time Accounting:** Automatically captures session start, finish, gross duration, net active work, and idle intervals without manual employee timecards.
- **Application & Process Telemetry:** Tracks foreground applications, document titles, and runtime durations to deliver complete transparency into enterprise software utilization.
- **Active vs. Idle Precision Analysis:** Uses native operating system input heuristics to differentiate between focused work and idle/away periods with customizable inactivity thresholds.
- **Dual Transport Topology:** Fully functional in both air-gapped internal corporate subnets (via local SMB replication) and distributed multi-site networks (via secure HTTPS REST gateways).
- **Executive Single-Pane Dashboard:** Modern, responsive dark-themed management console providing real-time team status badges, individual drill-downs, and historical analytics.
- **Custom Corporate Provisioning:** Workstation aliases, organizational departments, polling intervals, and retention windows tailored specifically for each client environment.

---

## 📊 System Visual Showcase

### 1. Central Executive Dashboard
A high-level view of all company workstations, live status badges (🟢 Active, 🟡 Idle/Away, ⚪ Offline), top utilized applications, and daily corporate KPIs.

![Central Executive Dashboard](screenshots/dashboard-overview.png)

### 2. Individual Employee Activity Profile
Granular audit of a single employee's workday (e.g. *John Smith*, IT Department): chronological activity timeline, active vs. idle ratio, and complete per-application usage breakdown.

![Individual Employee Activity Details](screenshots/user-activity-details.png)

### 3. Organization-Wide Application Statistics
Comprehensive inventory of all software executed across the company, ranked by total usage duration, percentage of enterprise work time, and cross-departmental distribution.

![Application Usage Statistics](screenshots/application-statistics.png)

### 4. Executive Management & Compliance Reporting
Comparative team matrices, department productivity benchmarks, and schedule adherence metrics for weekly and monthly performance evaluations.

![Activity & Working Time Reports](screenshots/reporting-overview.png)

---

## ⚙️ How the System Operates

```mermaid
flowchart LR
    subgraph Corporate_Fleet ["💻 Corporate Workstations"]
        W1["🖥️ Workstation 1<br/>Silent Daemon Agent"]
        W2["🖥️ Workstation 2<br/>Silent Daemon Agent"]
        WN["🖥️ Workstation N<br/>Silent Daemon Agent"]
    end

    subgraph Data_Routing ["🔀 Secure Data Transport Layer"]
        SMB["📁 On-Premise Storage<br/>(Air-Gapped SMB Share)"]
        API["🛡️ Central Gateway<br/>(TLS 1.3 / HTTPS REST)"]
    end

    subgraph Presentation ["📊 Executive Analytics Layer"]
        Dash["📈 Work Time Stat Console<br/>• Real-Time Presence Status<br/>• Chronological Timelines<br/>• Application Duration Audits<br/>• Multi-Date Archives"]
    end

    W1 -->|Local Buffer / 5s Poll| SMB
    W2 -->|Local Buffer / 5s Poll| SMB
    WN -->|Local Buffer / 5s Poll| SMB

    W1 -.->|Secure Push / 10s| API
    W2 -.->|Secure Push / 10s| API
    WN -.->|Secure Push / 10s| API

    SMB --> Dash
    API --> Dash
```

1. **Lightweight Agent Execution:** A background service daemon runs quietly on target Windows endpoints. It queries native Win32 API endpoints every 5 seconds to detect user activity and foreground window titles.
2. **Local Resiliency Buffer:** Telemetry is buffered in local non-volatile storage (`ProgramData`) to ensure zero data loss during corporate network disconnects.
3. **Transport & Aggregation:** Data is transmitted either to an internal corporate network share or through an encrypted HTTPS endpoint.
4. **Instant Analytical Rendering:** The management dashboard renders live workstation statuses, calculates idle vs. productive metrics, and provides historical data analysis across custom date windows (Today, Yesterday, Last 7 Days, Last 30 Days).

---

## 💻 Infrastructure Requirements

### Monitored Client Workstations
- **Operating System:** Windows 11, Windows 10, Windows 8.1, or Windows Server (both 64-bit and 32-bit architectures supported).
- **Environment:** Native Windows PowerShell runtime with standard Win32 API support.
- **Resource Footprint:** Less than 0.1% CPU consumption; less than 25 MB RAM.
- **User Permissions:** Administrative rights required once during initial setup; runs seamlessly in background under local system or standard user context.

### Central Collection & Management Layer
- **Local Network Deployment (Air-Gapped):** Standard Windows Server or Linux Samba SMB share with appropriate read/write share permissions.
- **Cloud / Distributed Deployment:** Linux or Windows host with HTTPS support and reverse proxy (Nginx / Cloudflare SSL).
- **Client Access:** Modern web browser (Chrome, Edge, Firefox, Safari) with responsive desktop and tablet support.

---

## 🤝 Individual Engagement & Inquiry

**Work Time Stat** is delivered exclusively as an engineered, individually deployed corporate solution. We do not provide generic public self-service downloads.

To schedule an architecture consultation, request a customized live demonstration, or receive an individual implementation quotation for your organization:

- 👤 **Lead Engineer:** Vladimir Bulantsev (@GinCz)
- 📍 **Location:** Prague, Czech Republic (Available for EU & Global Deployments)
- ✉️ **Direct Email:** [gin@volny.cz](mailto:gin@volny.cz)
- 💼 **LinkedIn:** [linkedin.com/in/gincz](https://www.linkedin.com/in/gincz/)
- 🐙 **GitHub Portfolio:** [github.com/GinCz](https://github.com/GinCz)

---

<div align="center">

<sub>Work Time Stat &copy; 2026. Engineered by VladiMIR + AI · Custom Corporate Deployments.</sub>

</div>
