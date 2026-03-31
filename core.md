siga o seguinte Core.md para melhorar esse app.

# SaaS Specification: Pluribeauty


## 1. Project Overview & Purpose

**Pluribeauty** is a high-end marketplace for beauty and wellness services. It connects clients with specialized professionals (hairdressers, barbers, manicurists, etc.). 

- **Core Value Prop**: Seamless discovery and booking of beauty services with a focus on both salon-based and home-visit (domicílio) models.

- **Target Audience**: Beauty-conscious clients looking for quality professionals and service providers seeking to manage their bookings and portfolio.




---




## 2. Database Schema (Entities)




### `Service` (Serviços)

Defines the offerings provided by a professional.

- `professional_id` (String, Required): ID of the owner.

- `name` (String, Required): Name of the service (e.g., "Corte Social").

- `category` (Enum): `cabelo`, `barba`, `unhas`, `estetica`, `maquiagem`, `outros`.

- `description` (String): Detailed service description.

- `price` (Number, Required): Cost of the service.

- `duration_minutes` (Number): Expected duration.

- `available_at` (Array of Strings): `salao`, `domicilio`.




### `Professional` (Profissionais)

The core profile for service providers.

- `name` (String, Required): Professional/Business name.

- `cover_photo` / `profile_photo` (String): Image URLs.

- `specialties` (Array): e.g., `['cabelo', 'barba']`.

- `bio` (String): Professional summary.

- `location` (Object): `address`, `city`, `lat`, `lng`.

- `service_types` (Array): `salao`, `domicilio`.

- `rating` (Number): Average score (1-5).

- `total_reviews` (Number): Count of ratings.

- `portfolio` (Array): List of image URLs.

- `is_featured` (Boolean): For landing page promotion.




### `Booking` (Agendamentos)

Manages the appointment lifecycle.

- `client_id` (String): User's ID.

- `professional_id` (String): Professional's ID.

- `services` (Array of Objects): `service_id`, `service_name`, `price`.

- `date` (Date) / `time` (String): e.g., "2024-04-01", "14:30".

- `location_type` (Enum): `salao`, `domicilio`.

- `address` (String): Required if `domicilio`.

- `status` (Enum): `pendente`, `confirmado`, `concluido`, `cancelado`.

- `total_price` (Number): Sum of selected services.




### `Favorite`, `Message`, `Notification`, `Review`

- **Favorite**: Links `user_id` to `professional_id`.

- **Message**: Chat system between `client` and `professional`.

- **Notification**: Types: `new_booking`, `booking_confirmed`, `booking_cancelled`.

- **Review**: Client feedback linked to `booking_id` and `professional_id` (Rating 1-5).




### `ProfessionalApplication`

Detailed verification form for becoming a platform professional (includes documents like CPF/CNPJ, RG/CNH photos, and portfolio links).




---




## 3. Pages & Routing




- `/Descobrir` (Home): Main landing page. Features a search bar, search radius slider (1km - 50km), and specialty category cards (Cabelo, Barba, Unhas, etc.).

- `/ListaProfissionais`: Grid of `ProfessionalCard` components. Includes filters for rating, price range, and location.

- `/ProfissionalDetalhe/[id]`: Detailed view. Header with photos, tabbed sections for "Sobre" (About), "Serviços" (Multi-select service list), and "Portfólio" (Image gallery). Floating footer showing total price and "Agendar" button.

- `/Agendamento`: Multi-step flow:

1. Select location (Salão or Domicílio).

2. Date & Time picker (Date-fns based).

3. Confirmation.

- `/Agenda`: User's list of past and upcoming bookings with status badges.

- `/Chat/[id]`: Direct messaging interface.

- `/Mapa`: Interactive map view of nearby professionals.

- `/CadastroProfissional`: Multi-step application wizard for onboarding.




---




## 4. UI/UX & Design System




This section defines the complete visual identity and design guidelines of the Pluribeauty platform, enabling any LLM to accurately recreate the exact same styling and design in a new Astro/React project.




### 4.1 Visual Identity & Color Palette

The platform utilizes an "Earth Tones" palette evoking sophistication, wellness, and natural beauty.




**Primary Colors (CSS Variables):**

```css

:root {

--terracotta: #A0522D;   /* Main actions, primary buttons, active icons */

--beige: #F5F0E8;        /* Secondary backgrounds, light cards */

--warm-brown: #8B7355;   /* Secondary accents, design elements */

--olive: #6B7B3F;        /* Organic details, badges, or specific categories */

--off-white: #FAF9F6;    /* Main page background (Body) */

--soft-black: #2D2926;   /* Primary typography, titles, high contrast text */

--sand: #D4C4B0;         /* Borders, dividers, inactive inputs */

}

```




### 4.2 Typography

The typographic combination mixes classic editorial with modern functional design.




- **Editorial Serif (Titles/Elegance):** `'Cormorant Garamond'`, Georgia, serif.

- Used in: Section titles, category names in cards, highlighted text.

- Weights: 400 (regular), 500 (medium), 600 (semibold).

- **Sans-Modern (Interface/Reading):** `'Inter'`, system-ui, sans-serif.

- Used in: Body text, labels, buttons, and navigation.

- Weights: 300 (light), 400 (regular), 500 (medium), 600 (semibold).




### 4.3 Layout Structure (Mobile-First)

The application is designed primarily for mobile devices, simulating a native app feel.




- **Global Background:** `bg-[#FAF9F6]` (Off-white).

- **Bottom Navigation Bar:**

- Fixed to the bottom of the screen.

- Items: Descobrir (Compass), Mapa (MapPin), Favoritos (Heart), Agenda (Calendar), Perfil (User).

- Style: Off-white background, light top border in Sand (`#D4C4B0`).

- Main Padding: When the Nav is visible, the `<main>` tag must have `pb-20` to avoid content overlap.

- **Conditional Navigation:** The bottom bar is hidden on direct flow pages like `ProfissionalDetalhe`, `Agendamento`, and `Chat`.




### 4.4 Component Styles




#### Category/Specialty Cards (Grid)

- **Container:** `aspect-[4/5]` ratio, rounded corners `rounded-2xl`.

- **Images:** Fill the entire card using `object-cover`.

- **Overlay:** Dark gradient at the bottom for text readability, or semi-transparent colored background.

- **Interaction (Framer Motion):**

- Hover: `scale: 1.02`.

- Tap: `scale: 0.98`.

- **Colors by Category:**

- Hair/Aesthetics (Cabelo/Estética): Terracotta (#A0522D)

- Beard/Waxing (Barba/Depilação): Warm Brown (#8B7355)

- Nails (Unhas): Olive (#6B7B3F)

- Makeup (Maquiagem): Sand (#D4C4B0)




#### Forms and Inputs

- **Inputs:** `rounded-xl`, borders in `--sand`, focus ring in `--terracotta`.

- **Sliders (Filters):** Track in `--sand`, Thumb and active fill in `--terracotta`.




#### Buttons

- **Primary:** Terracotta background, Off-white text, `rounded-full` or `rounded-xl`.

- **Secondary:** Sand borders, transparent or Beige background.

- **Floating Action Bar (FAB):** Used in detail and agendamento pages for immediate CTAs.




### 4.5 Spacing & Borders

- **Borders:** Thin (`1px`), color `#D4C4B0` (sand).

- **Border Radius:**

- Cards and Sections: `2xl` (16px) or `3xl` (24px).

- Buttons/Inputs: `xl` (12px) or `full`.

- **Spacing Grid:** Tailwind-based (generally `p-4` or `p-6` for main containers).




### 4.6 Animations (Framer Motion)

The interface must be fluid with smooth transitions:

- **Page Entry:** Fade-in with a slight vertical displacement (slide up).

- **Micro-interactions:** Smooth scaling on buttons and clickable cards for tactile feedback.




---




## 5. Key Business Logic

1. **Multi-Service Selection**: Users can select multiple services (e.g., Haircut + Beard) and the system must dynamically sum the price and duration for the booking.

2. **Availability Check**: Booking logic prevents past dates and calculates available slots (predefined intervals: 09:00 - 19:00).

3. **Location Intelligence**: Distance calculation for professionals within the search radius.

4. **Professional Onboarding**: A rigorous verification process before a user is converted into a `Professional` entity.