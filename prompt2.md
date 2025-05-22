#CONTEXT:
Adopt the role of an expert mobile app architect and UX/UI strategist. You will design a full-scope development prompt for a comprehensive pet diary application called “PetPal.” The app must be cross-platform compatible, offer cloud-based functionality (using services like Supabase or AWS), and must never rely on mock data or local storage. It will include Google Sign-In, onboarding flows, and robust user permissions for multiple household members. Core features include pet profile management, barcode scanning, medicine reminders, AI behavioral analysis, CSV export, a store, and a freemium model based on the number of pets and features. The user interface should prioritize simplicity and functionality, featuring a floating bottom bar and intuitive pet filtering. All features should support real-time collaboration and cloud synchronization.

Additionally, incorporate the following advanced features:
	•	Push notification system for vet appointments, vaccination schedules, and health checks.
	•	A journal feature where users can log daily moods, meals, poop status, and walks.
	•	A “Lost Mode” to alert nearby users if a pet goes missing using geofencing.
	•	AI-driven suggestions for diet, exercise, or potential health alerts.
	•	QR code generation for each pet’s profile for easy scanning during visits or emergencies.
	•	Calendar view for upcoming pet activities.
	•	In-app chat for households to discuss pets.
	•	Integration with wearable pet health devices (via Bluetooth API or cloud-based services).
	•	Dark mode and accessibility settings.
	•	Multi-language support.
	•	Custom pet tags and emojis for fun UI personalization.
	•	Gamification: badges and achievements for consistent care.

#GOAL:
You will create a mega prompt for generating the full codebase, backend structure, and design system for PetPal. This should ensure all functionalities described are implemented using best practices for scalability, security, and UX.

#RESPONSE GUIDELINES:
Follow this expert step-by-step breakdown:
	1.	App Architecture & Stack Selection
	•	Recommend a tech stack suitable for cross-platform development (e.g., Flutter or React Native).
	•	Use Supabase or AWS Amplify as backend.
	•	Ensure all data is stored in the cloud with real-time sync.
	2.	Authentication & User Roles
	•	Google Sign-In
	•	Role-based access for multi-household use
	3.	Pet Management
	•	CRUD pet profiles with barcode input
	•	Pet filtering and sorting system
	•	Export data to CSV
	•	QR profile generation
	4.	Reminders & Notifications
	•	Push reminders for meds, walks, feeding, health checks
	•	Vet appointment calendar sync
	5.	Behavior & Health Intelligence
	•	AI analysis of behavior from journal logs or wearable data
	•	AI health recommendations
	6.	Daily Journal
	•	Log meals, poop, activity, mood
	•	View entries in timeline or calendar
	7.	Lost Mode
	•	GPS-based lost alert
	•	Push notification to other PetPal users in area
	•	Contact info attached to pet profile
	8.	In-App Store
	•	E-commerce integration
	•	Smart suggestions based on pet needs
	9.	Communication
	•	In-app chat for household coordination
	•	Commenting on logs or journal entries
	10.	UI/UX Design

	•	Floating bottom bar with icons: Home, Journal, Store, Reminders, Settings
	•	Simple forms for data input
	•	Fun customization: pet emojis, badges

	11.	Advanced Integrations

	•	Bluetooth sync with health trackers (FitBark, Whistle)
	•	Calendar and external app sync
	•	Localization and accessibility options

	12.	Freemium Structure

	•	Free: up to 2 pets, basic features
	•	Paid: more pets, AI features, behavior analysis, export, premium store

	13.	Gamification

	•	Badges for consistent feeding
	•	Achievement for daily logs
	•	Level up pets for engagement

#INFORMATION ABOUT ME:
	•	My app: PetPal
	•	Main features: [WEIGHT TRACKING], [BIRTHDAY TRACKING], [MEDICATION REMINDERS], [VET INFO STORAGE], [BARCODE SCANNING], [AI BEHAVIORAL ANALYSIS], [CSV EXPORT], [IN-APP STORE], [MULTI-USER ACCESS], [PET JOURNAL], [LOST MODE], [CALENDAR VIEW], [GEOFENCING], [AI DIET SUGGESTIONS], [WEARABLE INTEGRATION], [GAMIFICATION], [NOTIFICATIONS], [IN-APP CHAT]
	•	Cloud platform: [SUPABASE or AWS]
	•	Monetization: [FREEMIUM BASED ON PET COUNT AND FEATURE ACCESS]
	•	UI design: [SIMPLE, FLOATING BOTTOM BAR, EASY EDIT/FILTER/ADD]
	•	Pet data: [NEVER MOCK OR LOCAL, CLOUD ONLY]

#OUTPUT:
Generate a modular blueprint:
	•	Modules with purpose
	•	Technology per module
	•	Key function stubs
	•	UI notes per component
	•	Optional: Graph/database schema with user-pet-activity mapping

Ensure all generated components use real-time cloud sync, avoid local storage, and are ready for implementation.