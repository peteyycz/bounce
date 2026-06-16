pragma Singleton

import QtQuick

// Hard-coded list + thread content lifted straight from Hare Mail.html so
// the rendered screen matches the design mockup pixel for pixel.
QtObject {
    // palette index maps to Theme.avatars (0..5)
    readonly property var messages: [
        {
            from: "Maya Kessler", initials: "MK", palette: 0,
            time: "9:24 AM",
            subject: "Q3 brand refresh — final review before launch",
            snippet: "Hi Alex — we're almost there. The team incorporated your notes on the glass treatment and tightened the type scale. A couple of open questions before we ship…",
            chips: [{ kind: "work", label: "Work" }],
            unread: true, starred: false
        },
        {
            from: "Devon Vance", initials: "DV", palette: 2,
            time: "8:50 AM",
            subject: "Re: Contract renewal — RiverWorks × Northwind",
            snippet: "Thanks for the quick turnaround. Legal signed off on the revised terms this morning, so we're clear to proceed with the 12-month extension.",
            chips: [{ kind: "work", label: "Work" }],
            unread: true, starred: false
        },
        {
            from: "Figma Weekly", initials: "FW", palette: 1,
            time: "7:15 AM",
            subject: "The quiet comeback of skeuomorphism",
            snippet: "This week: why translucency and depth are back, three teams rethinking density, and a deep dive on variable fonts in product UI.",
            chips: [{ kind: "news", label: "Newsletter" }],
            unread: false, starred: true
        },
        {
            from: "Stripe", initials: "ST", palette: 3,
            time: "Yesterday",
            subject: "Your receipt from RiverWorks Studio",
            snippet: "Payment of $2,400.00 to RiverWorks Studio was successful. Invoice #INV-2041 is attached as a PDF.",
            chips: [{ kind: "receipt", label: "Receipt" }],
            unread: false, starred: false
        },
        {
            from: "Priya Tandon", initials: "PT", palette: 5,
            time: "Yesterday",
            subject: "Notes from the platform sync",
            snippet: "Quick recap of what we landed on: we're moving the token pipeline to the shared repo, and design QA shifts to Thursdays. Full notes below.",
            chips: [{ kind: "work", label: "Work" }],
            unread: false, starred: false
        },
        {
            from: "LinkedIn", initials: "LN", palette: 4,
            time: "Mon",
            subject: "You appeared in 14 searches this week",
            snippet: "See who's been looking at your profile and what they searched for.",
            chips: [{ kind: "news", label: "Newsletter" }],
            unread: false, starred: false
        },
        {
            from: "Calendar", initials: "CA", palette: 1,
            time: "Mon",
            subject: "Invitation: Design review @ Thu 2:00 PM",
            snippet: "Maya Kessler has invited you to a meeting. Conference room Aspen / Meet link included.",
            chips: [{ kind: "work", label: "Work" }],
            unread: false, starred: false
        },
        {
            from: "GitHub", initials: "GH", palette: 0,
            time: "Sun",
            subject: "[riverworks/shell] PR #214 merged",
            snippet: "feat: liquid bar transparency was approved by 2 reviewers and merged into main.",
            chips: [{ kind: "work", label: "Work" }],
            unread: false, starred: false
        }
    ]

    // Thread shown when the first row is selected.
    readonly property var thread: ({
        subject: "Q3 brand refresh — final review before launch",
        chips: [{ kind: "work", label: "Work" }],
        countLabel: "3 messages",
        messages: [
            {
                open: false,
                from: "You", initials: "AR", palette: -1,
                to: "to Maya, Priya",
                when: "Mon 4:12 PM",
                preview: "Sharing the latest board — the glass tokens are settled, take a look at the…",
                body: []
            },
            {
                open: false,
                from: "Priya Tandon", initials: "PT", palette: 5,
                to: "to You, Maya",
                when: "Mon 6:38 PM",
                preview: "Love it. One thing on the message-list density — can we test a comfortable…",
                body: []
            },
            {
                open: true,
                from: "Maya Kessler", initials: "MK", palette: 0,
                to: "to You, Priya · alex@riverworks.io",
                when: "9:24 AM",
                preview: "",
                body: [
                    "Hi Alex — we're almost there. The team incorporated your notes on the glass treatment and tightened the type scale, and honestly it's looking like the strongest version we've shipped.",
                    "A couple of open questions before we go live on Thursday:",
                    "1. On the marketing site hero, do we keep the frosted nav pinned, or let it dissolve into the page on scroll? Priya and I are split — I lean toward keeping it pinned for wayfinding.",
                    "2. The accent lavender reads beautifully in dark mode but feels a touch quiet on the light backgrounds. Worth nudging the saturation up ~8% for light, or do we keep one token for both?",
                    "If you can weigh in this morning we'll have time to land changes before the freeze. No need for a call — async is fine."
                ],
                sig: "Thanks,\nMaya\nBrand Design Lead · RiverWorks"
            }
        ]
    })
}
