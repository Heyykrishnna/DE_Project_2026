# PathForge

## Intelligent Internship Decision & Career Intelligence Platform

> **From guessing eligibility to achieving verifiable application
> readiness.**

PathForge is an intelligent internship decision and career intelligence
platform that helps students understand how well they align with real
internship requirements and, more importantly, what they need to do to
become stronger applicants.

Unlike conventional job portals that primarily list opportunities and
rely on basic keyword matching, PathForge evaluates a student's resume,
GitHub repositories, and technical competencies against internship
criteria. It combines deterministic scoring with semantic analysis to
produce explainable compatibility diagnostics, identify skill gaps,
recommend practical bridge projects, and create focused preparation
plans.

The platform turns an opaque match score into a clear, actionable path
toward application readiness.

------------------------------------------------------------------------

## 1. Problem Statement

Students often struggle to determine whether they are genuinely prepared
for an internship. Existing job platforms typically focus on discovering
and listing opportunities, while leaving students to interpret job
descriptions, assess their own qualifications, and decide how to close
gaps.

This creates several problems:

-   **Unclear eligibility:** Students cannot easily tell how closely
    their skills and experience match an internship's actual
    requirements.
-   **Keyword-based matching:** A simple keyword overlap can miss
    equivalent skills, relevant project experience, and contextual
    evidence.
-   **No actionable gap analysis:** Platforms rarely explain which
    requirements are missing or how important each gap is.
-   **Lack of direction:** Students may know they need to improve but
    not know which skills or projects would make the biggest difference.
-   **Unstructured preparation:** Preparation is often disconnected from
    a specific role and lacks a practical timeline.
-   **Fragmented applications:** Students track applications, deadlines,
    and follow-ups across multiple tools or spreadsheets.

PathForge addresses these problems by connecting opportunity analysis
with personalized preparation and application tracking.

## 2. Vision

To make internship preparation measurable, explainable, and accessible
by giving every student a clear understanding of where they stand, what
they are missing, and what they should do next.

## 3. Product Objectives

1.  Evaluate student profiles against internship requirements using
    structured and semantic analysis.
2.  Explain compatibility results through requirement-level evidence
    instead of presenting an unexplained percentage.
3.  Identify critical, important, and optional skill gaps.
4.  Recommend targeted bridge projects that help students demonstrate
    missing competencies.
5.  Generate practical, role-specific 7-day preparation roadmaps.
6.  Provide a centralized workflow to track internship applications from
    discovery to final outcome.
7.  Help students make informed decisions about which opportunities to
    prioritize.

## 4. Target Users

### Primary users

-   University and college students seeking internships.
-   First-time applicants who need help understanding role expectations.
-   Students transitioning into a new technical domain.
-   Self-taught developers who want to validate their skills against
    market requirements.

### Secondary users

-   Career development cells and placement teams.
-   Student communities and technical clubs.
-   Mentors helping students prepare for internship applications.

## 5. Core Value Proposition

PathForge does not simply tell a student that an internship is a 72%
match. It explains:

-   Which requirements the student already satisfies.
-   What evidence supports each matched requirement.
-   Which requirements are partially satisfied or missing.
-   Which gaps are most important to address.
-   What projects or learning activities can help close those gaps.
-   What the student should complete over the next seven days.
-   How to track the opportunity and its application progress.

**Core promise:** Every compatibility result should lead to a practical
next step.

------------------------------------------------------------------------

## 6. Core Features

### 6.1 Student Career Profile

A centralized profile that represents a student's qualifications and
technical experience.

**Profile inputs:**

-   Resume upload and parsed experience.
-   Technical skills and proficiency levels.
-   Education and academic information.
-   Projects, achievements, and certifications.
-   GitHub profile and repository information.
-   Relevant links such as portfolio and LinkedIn.
-   Student-provided interests and preferred roles.

**Expected output:**

A structured student profile that can be evaluated against multiple
internship opportunities.

### 6.2 Internship Requirement Analysis

PathForge evaluates internship descriptions and converts them into
structured requirements.

**Analysis dimensions:**

-   Required technical skills.
-   Preferred or bonus skills.
-   Tools, frameworks, and technologies.
-   Experience expectations.
-   Project and portfolio expectations.
-   Role responsibilities.
-   Eligibility constraints, when explicitly provided.

The system should distinguish mandatory requirements from preferred
qualifications so that a missing bonus skill does not carry the same
impact as a missing core requirement.

### 6.3 Hybrid Compatibility Engine

The central intelligence layer combines deterministic scoring and
semantic analysis.

**Deterministic analysis**

Uses explicit, rule-based checks for structured requirements, such as:

-   Skill presence.
-   Required tools and technologies.
-   Experience or project evidence.
-   Explicit eligibility conditions.
-   Other measurable criteria defined by the role.

**Semantic analysis**

Uses semantic comparison to understand contextual relevance, such as:

-   Different wording for equivalent technical skills.
-   Relevant experience described without exact keywords.
-   Project descriptions that demonstrate a required competency.
-   Contextual relationships between technologies and responsibilities.

**Combined result**

The engine produces a compatibility assessment with supporting evidence,
confidence indicators, and requirement-level explanations.

> The compatibility score is a decision-support signal, not a guarantee
> of selection or an objective measure of a student's overall ability.

### 6.4 Explainable Compatibility Diagnostics

Every evaluation should make its reasoning understandable.

For each requirement, show:

  -----------------------------------------------------------------------
  Status                              Meaning
  ----------------------------------- -----------------------------------
  Matched                             Relevant evidence was found in the
                                      student's profile.

  Partially matched                   Some relevant evidence exists, but
                                      it may be incomplete.

  Missing                             No sufficient supporting evidence
                                      was found.

  Needs verification                  The available information is
                                      ambiguous or insufficient to make a
                                      reliable assessment.
  -----------------------------------------------------------------------

Diagnostics should include:

-   Requirement name and importance.
-   Match status.
-   Evidence source, such as resume, GitHub, or student profile.
-   Explanation of why the requirement received that status.
-   Suggested next action.

### 6.5 Skill Gap Identification

PathForge converts diagnostics into a prioritized improvement plan.

**Gap categories:**

-   **Critical gaps:** Missing core requirements that materially affect
    role readiness.
-   **Important gaps:** Skills or experience that strengthen the
    application.
-   **Optional gaps:** Bonus qualifications that may provide additional
    value.

Each gap should include its relevance to the internship and a
recommended way to address it.

### 6.6 Targeted Bridge Project Recommendations

When a student lacks demonstrable experience, PathForge recommends
focused projects designed to build and showcase the missing
competencies.

Each recommendation should include:

-   Project title and objective.
-   Skills and technologies to demonstrate.
-   Suggested feature scope.
-   Expected deliverables.
-   Evidence the student should add to their portfolio or GitHub.
-   Estimated effort or difficulty.
-   Connection to the internship requirement it addresses.

Recommendations should be specific enough to build, not generic
suggestions such as "learn React" or "practice Python."

### 6.7 7-Day Preparation Roadmap

PathForge generates a structured seven-day plan based on the student's
most important gaps and the target internship.

A roadmap may include:

  -----------------------------------------------------------------------
  Day                     Focus                   Expected outcome
  ----------------------- ----------------------- -----------------------
  Day 1                   Understand the role and Clear priority list and
                          review core             baseline assessment
                          requirements            

  Day 2                   Study the               Notes and small
                          highest-priority        practice exercises
                          missing concept         

  Day 3                   Apply the concept       Working feature or
                          through implementation  technical exercise

  Day 4                   Build a targeted        Demonstrable project
                          bridge-project          progress
                          component               

  Day 5                   Complete and document   Usable project with
                          the project             clear documentation

  Day 6                   Improve resume and      Role-aligned
                          portfolio evidence      application materials

  Day 7                   Revise, practice, and   Final checklist and
                          review readiness        application decision
  -----------------------------------------------------------------------

The actual plan should adapt to the student's profile, role
requirements, available time, and gap severity. The roadmap is a focused
preparation guide, not a promise that a student can master every missing
skill in seven days.

### 6.8 Application Tracking

A centralized dashboard for managing internship applications.

**Suggested application stages:**

1.  Saved
2.  Researching
3.  Preparing
4.  Ready to Apply
5.  Applied
6.  Assessment
7.  Interview
8.  Offer
9.  Rejected
10. Withdrawn

**Application information:**

-   Company and role.
-   Internship description and source link.
-   Application deadline.
-   Date saved and date applied.
-   Current application status.
-   Notes and follow-up reminders.
-   Related compatibility assessment.
-   Preparation roadmap progress.

### 6.9 Career Intelligence Dashboard

A unified overview of a student's internship readiness and application
activity.

Potential dashboard sections:

-   Profile completion.
-   Skills overview.
-   Internship compatibility summaries.
-   Highest-priority skill gaps.
-   Active preparation roadmaps.
-   Bridge-project progress.
-   Application pipeline.
-   Upcoming deadlines and follow-ups.

------------------------------------------------------------------------

## 7. Typical User Journey

1.  **Create a profile:** The student signs up and adds their resume,
    GitHub profile, skills, and relevant experience.
2.  **Discover an internship:** The student adds or selects an
    internship opportunity.
3.  **Analyze requirements:** PathForge extracts and structures the
    role's requirements.
4.  **Evaluate compatibility:** The hybrid engine compares the student's
    qualifications with the role.
5.  **Review diagnostics:** The student sees matched, partially matched,
    missing, and unverified requirements.
6.  **Prioritize gaps:** PathForge identifies the most important areas
    to improve.
7.  **Build evidence:** The student receives bridge-project
    recommendations.
8.  **Prepare strategically:** A personalized seven-day roadmap guides
    preparation.
9.  **Track the application:** The student moves the opportunity through
    the application pipeline.
10. **Update and reassess:** As the student adds skills, projects, or
    experience, the profile can be reassessed.

------------------------------------------------------------------------

## 8. System Architecture

PathForge can be organized into the following logical layers.

### 8.1 Frontend Layer

Responsible for the student-facing experience:

-   Authentication and onboarding.
-   Profile management.
-   Resume upload.
-   Internship discovery and details.
-   Compatibility reports.
-   Skill-gap visualizations.
-   Project recommendations.
-   Preparation roadmaps.
-   Application tracking dashboard.

### 8.2 Backend/API Layer

Responsible for application logic and coordination:

-   User and profile management.
-   Resume processing orchestration.
-   Internship data management.
-   Evaluation requests.
-   Roadmap and recommendation generation.
-   Application status management.
-   Data validation and access control.

### 8.3 Intelligence Layer

Responsible for transforming raw information into useful career
insights:

-   Resume parsing and normalization.
-   Internship requirement extraction.
-   Skill taxonomy and synonym mapping.
-   Deterministic scoring.
-   Semantic similarity and evidence analysis.
-   Explainability generation.
-   Skill-gap prioritization.
-   Bridge-project recommendation.
-   Roadmap generation.

### 8.4 Data Layer

Stores the information required to operate the platform:

-   User profiles.
-   Resume metadata and extracted information.
-   Skills and competencies.
-   Internship opportunities.
-   Structured role requirements.
-   Evaluation results and evidence.
-   Project recommendations.
-   Roadmaps and progress.
-   Application records and activity history.

### 8.5 External Integrations

Potential integrations include:

-   GitHub API for public profile and repository signals.
-   Resume/document parsing services.
-   Semantic embedding or language-model APIs.
-   Internship listing sources and company career pages.
-   Email or notification services.

Integrations should respect platform terms, API limits, user consent,
and data privacy requirements.

------------------------------------------------------------------------

## 9. Compatibility Scoring Framework

The scoring engine should be transparent, configurable, and versioned.

A possible starting model is:

\[ C = `\frac{\sum_{i=1}^{n} w_i m_i}{\sum_{i=1}^{n} w_i}`{=tex}
`\times 100`{=tex} \]

Where:

-   \(C\) is the compatibility score.
-   \(n\) is the number of evaluated requirements.
-   (w_i) is the importance weight of requirement (i).
-   (m_i) is the match value for requirement (i).

An initial match-value convention could be:

-   Matched: 1.0
-   Partially matched: 0.5
-   Missing: 0.0
-   Needs verification: excluded from the confirmed score or handled
    through a clearly disclosed uncertainty rule.

The exact treatment of unverified requirements must be consistent and
visible to users. The system should also display coverage, meaning how
much of the role's requirements could be evaluated with available
evidence.

### Scoring principles

-   Mandatory requirements should carry more weight than optional
    requirements.
-   Evidence quality should influence match confidence.
-   Semantic similarity alone should not prove practical competence.
-   Missing profile information should not automatically be treated as
    proof that a student lacks a skill.
-   Students should be able to inspect the evidence behind each result.
-   Scoring weights and model versions should be recorded for
    reproducibility.

**Important:** The formula above is a proposed baseline, not a validated
hiring model. It should be tested against realistic examples and refined
before being used for consequential recommendations.

------------------------------------------------------------------------

## 10. Data Model (Conceptual)

The following entities provide a starting point for database design.

  -----------------------------------------------------------------------
  Entity                              Purpose
  ----------------------------------- -----------------------------------
  User                                Authentication and account
                                      information

  StudentProfile                      Education, interests, links, and
                                      profile metadata

  Resume                              Uploaded resume and parsed content

  Skill                               Normalized technical or
                                      professional competency

  StudentSkill                        Student's claimed or evidenced
                                      skill and proficiency

  Project                             Student project information and
                                      repository links

  Internship                          Opportunity details and source
                                      information

  InternshipRequirement               Structured requirements for an
                                      internship

  Evaluation                          Overall compatibility result and
                                      scoring version

  RequirementAssessment               Requirement-level status, evidence,
                                      and confidence

  SkillGap                            Prioritized missing or partially
                                      matched competency

  BridgeProject                       Recommended project and expected
                                      deliverables

  Roadmap                             Seven-day preparation plan

  RoadmapTask                         Individual task, status, and
                                      expected outcome

  Application                         Student's application record and
                                      current status

  ApplicationActivity                 Timeline of status changes, notes,
                                      and follow-ups
  -----------------------------------------------------------------------

Relationships should support multiple evaluations for one student and
multiple applications across different internships.

------------------------------------------------------------------------

## 11. Suggested Technology Stack

The stack below is a practical starting point and can be changed based
on implementation constraints.

  -----------------------------------------------------------------------
  Layer                               Suggested technology
  ----------------------------------- -----------------------------------
  Frontend                            React or Next.js

  Language                            TypeScript

  Styling                             Tailwind CSS

  Backend                             Node.js with a structured API
                                      framework

  Database                            PostgreSQL

  Authentication                      Supabase Auth or an equivalent
                                      provider

  File storage                        Supabase Storage or compatible
                                      object storage

  Semantic analysis                   Embedding model and language-model
                                      API

  Resume parsing                      Dedicated parser or controlled
                                      extraction pipeline

  GitHub integration                  GitHub REST or GraphQL API

  Deployment                          Vercel for frontend and a suitable
                                      backend hosting provider

  Monitoring                          Application logs and error
                                      monitoring
  -----------------------------------------------------------------------

Choose technologies based on the team's experience, expected scale,
cost, and deployment needs. Avoid adding services before the product
requires them.

------------------------------------------------------------------------

## 12. MVP Scope

The first version should prove the core value proposition: evaluating an
internship against a student's profile and turning the result into
actionable preparation.

### Must have

-   Student authentication.
-   Student profile creation.
-   Resume upload and basic parsing.
-   Manual internship description input.
-   Internship requirement extraction.
-   Basic GitHub profile or repository integration.
-   Hybrid compatibility assessment.
-   Requirement-level explainability.
-   Prioritized skill-gap report.
-   Bridge-project recommendations.
-   Seven-day preparation roadmap.
-   Basic application tracking.

### Should have

-   Saved internship opportunities.
-   Multiple evaluations per student.
-   Roadmap task completion.
-   Application deadline reminders.
-   Profile and assessment history.
-   Exportable compatibility report.

### Could have later

-   Automated internship discovery.
-   More advanced repository analysis.
-   Portfolio analysis.
-   Peer or mentor feedback.
-   Institution-level analytics.
-   Interview preparation based on role requirements.
-   Personalized career-path recommendations.

### Out of scope for the initial MVP

-   Guaranteeing internship selection.
-   Automatically applying to jobs on a student's behalf.
-   Ranking students for employers.
-   Predicting hiring decisions.
-   Replacing human career counselors or recruiters.

------------------------------------------------------------------------

## 13. Non-Functional Requirements

### Performance

-   Common dashboard and profile interactions should feel responsive.
-   Long-running parsing and evaluation tasks should run asynchronously
    where appropriate.
-   The interface should communicate processing states and failures
    clearly.

### Reliability

-   Evaluation results should be reproducible for a recorded input and
    scoring version.
-   Failed integrations should not corrupt profile or application data.
-   Users should be able to retry failed analysis jobs safely.

### Security and Privacy

-   Protect personal information and uploaded resumes.
-   Use secure authentication and authorization.
-   Restrict access to private user data.
-   Request explicit consent before accessing connected accounts.
-   Store only the data required for the stated product purpose.
-   Provide clear data retention and deletion controls.
-   Never expose private GitHub repository data without appropriate
    authorization.

### Explainability and Fairness

-   Show evidence and reasoning for assessments.
-   Avoid treating missing data as a confirmed lack of ability.
-   Do not use sensitive personal characteristics to calculate
    compatibility.
-   Provide a way to correct inaccurate extracted profile information.
-   Make clear that assessments are advisory and may contain errors.

### Accessibility

-   Support keyboard navigation.
-   Use readable contrast and typography.
-   Provide labels and accessible feedback for interactive elements.
-   Do not rely on color alone to communicate match status.

------------------------------------------------------------------------

## 14. Success Metrics

Measure whether PathForge helps students make better decisions and take
meaningful action, not just whether they generate many compatibility
reports.

### Activation

-   Percentage of users completing their student profile.
-   Percentage of users completing their first internship evaluation.
-   Time from sign-up to first useful evaluation.

### Engagement

-   Number of internships evaluated per active student.
-   Percentage of users opening their diagnostics.
-   Roadmap task completion rate.
-   Bridge-project recommendation engagement.

### Application outcomes

-   Percentage of evaluated internships added to the application
    tracker.
-   Percentage of users moving from preparation to application.
-   Application pipeline completion and status-update rates.
-   Student-reported usefulness of recommendations.

### Quality

-   Accuracy of extracted internship requirements.
-   Agreement between requirement assessments and human review.
-   Rate of incorrect or unsupported skill matches.
-   Quality and relevance of bridge-project recommendations.
-   User-reported clarity of compatibility explanations.

Metrics should be defined with clear denominators and measured over
consistent time windows.

------------------------------------------------------------------------

## 15. Risks and Mitigation

  -----------------------------------------------------------------------
  Risk                    Potential impact        Mitigation
  ----------------------- ----------------------- -----------------------
  Inaccurate resume       Incorrect student       Allow users to review
  parsing                 profile                 and edit extracted
                                                  information

  Poor internship         Misleading evaluation   Show extracted
  requirement extraction                          requirements and allow
                                                  correction

  Semantic false          Skills appear matched   Require supporting
  positives               without evidence        evidence and confidence
                                                  thresholds

  Incomplete GitHub data  Underestimation of      Explain data coverage
                          project experience      and support manual
                                                  project entries

  Arbitrary scoring       Misleading              Version, test, and
  weights                 compatibility score     disclose scoring logic

  Generic project         Low practical value     Tie every
  recommendations                                 recommendation to a
                                                  specific skill gap

  Outdated internship     Wasted student effort   Display source and
  listings                                        last-verified date

  Overconfidence in AI    Poor student decisions  Use transparent
  output                                          limitations and
                                                  human-verifiable
                                                  evidence

  Privacy concerns        Loss of user trust      Minimize data
                                                  collection and provide
                                                  consent and deletion
                                                  controls
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 16. Product Principles

1.  **Explain, don't just score.** Every assessment should have a reason
    the student can inspect.
2.  **Evidence over keywords.** Relevant work and demonstrated skills
    matter more than exact wording.
3.  **Action over information.** Every identified gap should lead to a
    practical next step.
4.  **Progress over perfection.** The product should help students
    improve incrementally.
5.  **Honest uncertainty.** The platform must communicate when evidence
    is incomplete or ambiguous.
6.  **Student control.** Students should be able to review, correct, and
    manage their own information.

------------------------------------------------------------------------

## 17. Future Roadmap

### Phase 1: Core MVP

-   Authentication and student profiles.
-   Resume parsing.
-   Manual internship input.
-   Requirement extraction.
-   Initial compatibility engine.
-   Explainable diagnostics.
-   Skill-gap report.

### Phase 2: Actionable Preparation

-   Bridge-project recommendations.
-   Seven-day preparation roadmaps.
-   Roadmap progress tracking.
-   Resume improvement suggestions.
-   Assessment history.

### Phase 3: Application Intelligence

-   Application pipeline.
-   Deadline and follow-up reminders.
-   Internship discovery integrations.
-   Saved opportunities.
-   Application analytics.

### Phase 4: Advanced Career Intelligence

-   Deeper GitHub repository analysis.
-   Portfolio evidence mapping.
-   Improved semantic evaluation.
-   Mentor feedback workflows.
-   Institution and community dashboards.
-   Long-term skill development insights.

------------------------------------------------------------------------

## 18. Definition of Done for the MVP

The MVP can be considered ready for initial user testing when a student
can:

-   Create and edit a career profile.
-   Upload a resume and review extracted information.
-   Add an internship description.
-   View structured internship requirements.
-   Receive a compatibility assessment.
-   Inspect the evidence and explanation for each requirement.
-   Identify prioritized skill gaps.
-   Receive at least one relevant bridge-project recommendation where a
    suitable gap exists.
-   Generate and complete tasks in a seven-day roadmap.
-   Save the internship and update its application status.
-   Understand the limitations of the assessment.

------------------------------------------------------------------------

## 19. Closing Statement

PathForge is built around a simple idea: students should not have to
guess whether they are ready for an internship, nor should they be left
with a score that tells them nothing about what to do next.

By combining structured evaluation, semantic understanding, explainable
diagnostics, targeted project recommendations, focused preparation
roadmaps, and application tracking, PathForge creates a practical bridge
between what the market expects and what a student can demonstrate.

**PathForge turns internship discovery into a guided journey from
opportunity to readiness.**
