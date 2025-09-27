/**
 * 📚 Learning Agent - Interactive Teaching and Skill Development
 *
 * Specializes in: Step-by-step learning, hands-on tutorials, skill development
 * Version: 2.0.0
 *
 * This agent provides structured learning experiences with:
 * - Interactive tutorials with guided practice
 * - Progressive skill building
 * - Hands-on exercises with real examples
 * - Best practice explanations
 * - Troubleshooting guidance
 * - Knowledge assessment and reinforcement
 */

class LearningAgent {
    constructor(options = {}) {
        this.learningStyle = options.learningStyle || 'hands-on'; // hands-on, visual, theoretical
        this.skillLevel = options.skillLevel || 'intermediate'; // beginner, intermediate, advanced
        this.pacePreference = options.pacePreference || 'step-by-step'; // step-by-step, fast-track
        this.practiceMode = options.practiceMode || 'guided'; // guided, independent

        this.currentSession = {
            topic: null,
            progress: [],
            completedSteps: [],
            nextActions: [],
            resources: []
        };
    }

    /**
     * Create a comprehensive learning plan for Git branching and workflow
     */
    createGitBranchingTutorial() {
        return {
            title: "🌿 Professional Git Branching & Workflow Mastery",
            description: "Learn to implement GitFlow with semantic versioning like a pro",

            prerequisites: [
                "✅ Basic git knowledge (commit, push, pull)",
                "✅ GitHub repository access",
                "✅ VS Code or preferred git client"
            ],

            learningObjectives: [
                "🎯 Understand GitFlow branching strategy",
                "🎯 Implement main → develop → uat → feature workflow",
                "🎯 Master semantic versioning (v1.0.0 format)",
                "🎯 Set up branch protection rules",
                "🎯 Create professional development workflow"
            ],

            modules: [
                {
                    module: 1,
                    title: "🏗️ Setting Up Your Branch Structure",
                    duration: "15 minutes",
                    type: "hands-on",

                    theory: {
                        concept: "GitFlow Branching Strategy",
                        explanation: `
GitFlow uses these core branches:
• main (production) - Always deployable, tagged versions
• develop - Integration branch for features
• uat - User acceptance testing before production
• feature/* - Individual feature development
• hotfix/* - Emergency production fixes
• release/* - Preparing new production releases`,

                        benefits: [
                            "✅ Clean separation of environments",
                            "✅ Parallel development without conflicts",
                            "✅ Controlled releases with testing gates",
                            "✅ Easy rollbacks and hotfixes",
                            "✅ Clear version history"
                        ]
                    },

                    practicalSteps: [
                        {
                            step: 1,
                            title: "Create develop branch",
                            command: "git checkout -b develop",
                            explanation: "Creates develop branch from current main branch",
                            expectedResult: "Switched to a new branch 'develop'"
                        },
                        {
                            step: 2,
                            title: "Push develop to remote",
                            command: "git push -u origin develop",
                            explanation: "Pushes develop branch to GitHub and sets upstream tracking",
                            expectedResult: "Branch 'develop' set up to track remote branch 'develop'"
                        },
                        {
                            step: 3,
                            title: "Create UAT branch from develop",
                            command: "git checkout -b uat",
                            explanation: "UAT branch for testing before production deployment",
                            expectedResult: "Switched to a new branch 'uat'"
                        },
                        {
                            step: 4,
                            title: "Push UAT branch",
                            command: "git push -u origin uat",
                            explanation: "Make UAT branch available on remote",
                            expectedResult: "Branch 'uat' set up to track remote branch 'uat'"
                        },
                        {
                            step: 5,
                            title: "Return to develop",
                            command: "git checkout develop",
                            explanation: "Switch back to develop as your main working branch",
                            expectedResult: "Switched to branch 'develop'"
                        }
                    ],

                    validation: [
                        "✅ Check branches exist: `git branch -a`",
                        "✅ Verify remote tracking: `git branch -vv`",
                        "✅ Confirm on GitHub: All branches visible in repo"
                    ],

                    troubleshooting: {
                        "Branch already exists": "Use `git checkout existing-branch-name` instead",
                        "Push rejected": "Someone else may have created the branch - try `git fetch` first",
                        "Can't switch branches": "Commit or stash your current changes first"
                    }
                },

                {
                    module: 2,
                    title: "🏷️ Semantic Versioning Setup",
                    duration: "10 minutes",
                    type: "hands-on",

                    theory: {
                        concept: "Semantic Versioning (SemVer)",
                        format: "MAJOR.MINOR.PATCH (e.g., v1.0.0)",
                        rules: {
                            "MAJOR": "Breaking changes that require user action",
                            "MINOR": "New features, backwards compatible",
                            "PATCH": "Bug fixes, backwards compatible"
                        },
                        examples: [
                            "v1.0.0 - Initial production release",
                            "v1.1.0 - Added new feature",
                            "v1.1.1 - Fixed critical bug",
                            "v2.0.0 - Breaking API changes"
                        ]
                    },

                    practicalSteps: [
                        {
                            step: 1,
                            title: "Switch to main branch",
                            command: "git checkout main",
                            explanation: "Tags should be created from main branch",
                            expectedResult: "Switched to branch 'main'"
                        },
                        {
                            step: 2,
                            title: "Create initial version tag",
                            command: "git tag -a v1.0.0 -m 'Initial production release - Multi-project workspace'",
                            explanation: "Creates annotated tag with message for initial release",
                            expectedResult: "Tag v1.0.0 created"
                        },
                        {
                            step: 3,
                            title: "Push tag to remote",
                            command: "git push origin v1.0.0",
                            explanation: "Tags must be pushed separately to GitHub",
                            expectedResult: "Tag v1.0.0 pushed to origin"
                        },
                        {
                            step: 4,
                            title: "Verify tag creation",
                            command: "git tag -l",
                            explanation: "Lists all tags in repository",
                            expectedResult: "v1.0.0"
                        }
                    ],

                    validation: [
                        "✅ Tag visible locally: `git tag -l`",
                        "✅ Tag on GitHub: Check repository releases page",
                        "✅ Tag points to current commit: `git show v1.0.0`"
                    ]
                },

                {
                    module: 3,
                    title: "🛡️ Feature Branch Workflow",
                    duration: "20 minutes",
                    type: "hands-on",

                    theory: {
                        concept: "Feature Branch Development",
                        workflow: `
1. Create feature branch from develop
2. Develop feature with commits
3. Push feature branch to remote
4. Create Pull Request to develop
5. Code review and testing
6. Merge to develop via PR
7. Delete feature branch`,
                        namingConvention: "feature/description-of-feature"
                    },

                    practicalSteps: [
                        {
                            step: 1,
                            title: "Ensure on develop branch",
                            command: "git checkout develop",
                            explanation: "Always branch from develop for new features",
                            expectedResult: "Switched to branch 'develop'"
                        },
                        {
                            step: 2,
                            title: "Create feature branch",
                            command: "git checkout -b feature/git-workflow-setup",
                            explanation: "Use descriptive naming: feature/what-youre-building",
                            expectedResult: "Switched to a new branch 'feature/git-workflow-setup'"
                        },
                        {
                            step: 3,
                            title: "Make a small change",
                            command: "# Edit a file (e.g., add comment to CLAUDE.md)",
                            explanation: "Practice the workflow with a real change",
                            expectedResult: "File modified"
                        },
                        {
                            step: 4,
                            title: "Commit the change",
                            command: "git add . && git commit -m 'feat: add git workflow documentation'",
                            explanation: "Use conventional commit format: type: description",
                            expectedResult: "Commit created with message"
                        },
                        {
                            step: 5,
                            title: "Push feature branch",
                            command: "git push -u origin feature/git-workflow-setup",
                            explanation: "Make feature branch available for collaboration",
                            expectedResult: "Feature branch pushed to remote"
                        }
                    ]
                }
            ],

            nextSteps: {
                immediate: [
                    "🔄 Practice creating another feature branch",
                    "📋 Set up Pull Request template",
                    "🛡️ Configure branch protection rules",
                    "📊 Install GitLens extension in VS Code"
                ],
                advanced: [
                    "🤖 Set up automated testing on PRs",
                    "📦 Configure semantic-release automation",
                    "🔀 Learn interactive rebase for clean history",
                    "🏷️ Automate version bumping"
                ]
            },

            resources: {
                tools: [
                    "VS Code + GitLens extension",
                    "Git Graph extension",
                    "GitHub CLI for advanced workflows",
                    "GitKraken for visual Git management"
                ],
                documentation: [
                    "Git Flow cheat sheet",
                    "Semantic Versioning specification",
                    "Conventional Commits standard",
                    "GitHub Flow vs Git Flow comparison"
                ]
            },

            assessment: {
                checkpoints: [
                    "✅ Can create and switch between branches",
                    "✅ Understands when to use each branch type",
                    "✅ Can create proper semantic version tags",
                    "✅ Follows feature branch workflow",
                    "✅ Uses conventional commit messages"
                ],
                practiceExercises: [
                    "Create hotfix/critical-bug-fix branch from main",
                    "Simulate release branch: release/v1.1.0",
                    "Practice merge conflicts resolution",
                    "Set up automated version tagging"
                ]
            }
        };
    }

    /**
     * Provide contextual help during learning
     */
    getContextualHelp(currentStep, issue = null) {
        const helpDatabase = {
            "branch-creation": {
                common_issues: [
                    "Branch name already exists - use `git branch -a` to check existing branches",
                    "Uncommitted changes prevent branching - commit or stash changes first",
                    "Not on correct parent branch - switch to develop before creating feature branch"
                ],
                best_practices: [
                    "Use descriptive branch names: feature/user-authentication",
                    "Keep feature branches small and focused",
                    "Regularly sync with develop: `git pull origin develop`"
                ]
            },
            "semantic-versioning": {
                decision_tree: {
                    "Breaking changes?": "Increment MAJOR (v2.0.0)",
                    "New features?": "Increment MINOR (v1.1.0)",
                    "Bug fixes only?": "Increment PATCH (v1.0.1)"
                },
                examples: [
                    "Database schema change → MAJOR",
                    "New API endpoint → MINOR",
                    "Fixed calculation bug → PATCH"
                ]
            }
        };

        return helpDatabase[currentStep] || "Help topic not found";
    }

    /**
     * Generate personalized learning path
     */
    generateLearningPath(userProfile) {
        const paths = {
            beginner: {
                pace: "slow",
                modules: ["basic-git", "branching-intro", "simple-workflow"],
                practice_frequency: "after-each-concept"
            },
            intermediate: {
                pace: "moderate",
                modules: ["gitflow-setup", "semantic-versioning", "pr-workflow"],
                practice_frequency: "after-each-module"
            },
            advanced: {
                pace: "fast",
                modules: ["advanced-branching", "automation", "ci-cd-integration"],
                practice_frequency: "project-based"
            }
        };

        return paths[userProfile.skillLevel] || paths.intermediate;
    }

    /**
     * Interactive tutorial session
     */
    startTutorialSession(topic = "git-branching") {
        this.currentSession.topic = topic;
        this.currentSession.startTime = new Date();

        console.log(`
🎓 Starting Learning Session: ${topic}
📅 ${new Date().toLocaleString()}
🎯 Learning Style: ${this.learningStyle}
⚡ Pace: ${this.pacePreference}

Ready to learn? Let's build your skills step by step!
        `);

        return this.createGitBranchingTutorial();
    }
}

// Export for use in other contexts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = LearningAgent;
}

// Example usage and testing
if (require.main === module) {
    const learningAgent = new LearningAgent({
        learningStyle: 'hands-on',
        skillLevel: 'intermediate',
        pacePreference: 'step-by-step'
    });

    const tutorial = learningAgent.startTutorialSession('git-branching');
    console.log("Tutorial created:", tutorial.title);
}