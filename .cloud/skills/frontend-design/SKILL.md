# Frontend Design System Layer
**Skill Name** frontend-design
**Description** Create distinctive, production-grade frontend interfaces with intentional, high-end design quality.
Used when building UI, screens, components, dashboards, or visual experiences.

**Design Thinking Workflow (MANDATORY BEFORE CODING)**
- **Purpose**
    - What problem does this UI solve?
    - Who is using it?
- **Tone Selection (Pick ONE Bold Direction)**
    - Choose a strong visual identity:
    - Brutalist / Raw
    - Retro-Futuristic
    - Editorial / Magazine
    - Luxury / High-End
    - Soft / Organic
    - Geometric / Art Deco
    - Playful / Toy-like
    - Industrial / Tactical
    - Minimal Zen
    - Maximalist Chaos
    - The design must commit fully to the chosen tone.
- **Differentiation Anchor**
    - Define one unforgettable visual element, such as:
        - signature animation
        - geometric layout system
        - bold type treatment
        - interactive gesture
        - layered glassmorphism
        - asymmetric layout

- **Flutter-Specific Design Translation**
    - Since this is Flutter (not HTML), map aesthetics to:
        - Web Concept	Flutter Equivalent
        - CSS variables	EColors, ThemeData, extensions
        - Grid layouts	GridView, CustomMultiChildLayout
        - Overlapping layouts	Stack + Positioned
        - Animations	AnimatedContainer, TweenAnimationBuilder, AnimationController
        - Scroll effects	CustomScrollView, Slivers
    - Hover effects	MouseRegion (desktop/web)
    - Glass / blur	BackdropFilter
    - Gradients	LinearGradient, ShaderMask

- **Aesthetic Execution Rules**
    - **Typography**
        - Use distinctive font pairings
        - Avoid default system fonts
        - Use size contrast aggressively
        - Integrate typography into layout (not just text)
    - **Color System**
        - Define palette in EColors
        - Use dominant base + sharp accents
        - Avoid washed-out or evenly distributed palettes
        - Prefer bold contrast or intentional harmony

- **Motion & Interaction**
    - Prioritize:
        - page load entrance sequences
        - staggered reveals
        - meaningful micro-interactions
        - Avoid random motion
        - Each animation must reinforce the theme

- **Spatial Composition**
    - Avoid boring center-column layouts
    - Use:
        - asymmetry
        - diagonal flow
        - overlapping elements
        - negative space OR dense editorial blocks

- **Background & Depth**
    - Enhance atmosphere with:
        - gradient meshes
        - subtle grain overlays
        - layered transparency
        - shadows with personality
        - geometric patterns
        - glow effects or light bloom

- **Anti-Patterns (STRICTLY AVOID)**
    - Generic AI UI styles
    - Inter / Roboto / Arial default look
    - Purple gradient on white background
    - Cookie-cutter SaaS dashboards
    - Safe, evenly spaced layouts with no identity

- **Every screen must feel designed, not generated**

- **Output Requirements When This Skill Is Triggered**
    - When generating UI:
        - Follow Flutter architecture rules first
        - Then apply design system decisions
        - Provide:
            - screen
            - widgets
            - controller (if needed)
            - constants used (EColors, ESizes)
        - Include animations and styling directly in widgets
        - Keep everything production-ready and structured

- **Example Invocation**
    - Use this skill when the user says things like:
        - “Build a landing page”
        - “Design a dashboard”
        - “Make this UI look better”
        - “Create a modern interface”
        - “Design my app home screen”
        - “I want this to feel futuristic / luxury / playful / geometric”

- **Philosophy**
    - Your apps should feel like:
        - A crafted product, not a template
        - A designed experience, not just a UI
        - A brand, not just a screen

- **Final Rule**
    - Engineering quality is required.
    - Design excellence is expected.
    - Both must exist together.