/**
 * BRAND CONFIGURATION
 *
 * Single source of truth for site branding.
 * Switch between presets via BRAND_PRESET env var.
 *
 * Usage: import { brand } from '../data/brand';
 */

export interface BrandConfig {
  // Core identity
  siteName: string;
  tagline: string;
  ownerName: string;
  ownerTitle: string;

  // Contact
  phone: string;
  email: string;
  location: string;
  serviceArea: string;

  // Virtual assistant
  virtualName: string;
  virtualTagline: string;

  // Content
  heroTitle: string;
  heroSubtitle: string;
  heroDescription: string;

  // Booking/availability
  availabilityText: string;

  // Footer
  footerTagline: string;
  credentials: string[];

  // URLs (optional overrides)
  logoUrl?: string;
  badgeUrl?: string;
}

// ═══════════════════════════════════════════════════════════════════════════════
// BRAND PRESETS
// ═══════════════════════════════════════════════════════════════════════════════

export const BRAND_PRESETS: Record<string, BrandConfig> = {

  // Old Head Plaster - Production site
  oldhead: {
    siteName: "Old Head Plaster",
    tagline: "Est. County Mayo",
    ownerName: "Daragh",
    ownerTitle: "Master Plasterer",

    phone: "860-574-7004",
    email: "daragh@oldheadplaster.com",
    location: "Madison, Connecticut",
    serviceArea: "Fairfield & New Haven Counties",

    virtualName: "Virtual Daragh",
    virtualTagline: "Plaster Expert",

    heroTitle: "The Finish",
    heroSubtitle: "Architects Specify",
    heroDescription: "Trusted by architects and interior designers for high-end residential, hospitality, and historic restoration projects across Connecticut.",

    availabilityText: "Currently accepting projects for Q2 2026",

    footerTagline: "Irish craftsmanship.\nConnecticut excellence.",
    credentials: ["EPA Lead-Safe Certified", "CT Licensed & Insured"],

    badgeUrl: "/images/virtual-daragh-badge.png",
  },

  // Demo Site - White-label template for prospects
  demo: {
    siteName: "Artisan Finishes",
    tagline: "Crafted Excellence",
    ownerName: "Your Name",
    ownerTitle: "Master Craftsman",

    phone: "(555) 123-4567",
    email: "hello@yourcompany.com",
    location: "Your City, State",
    serviceArea: "Your Service Region",

    virtualName: "Virtual Assistant",
    virtualTagline: "Project Consultant",

    heroTitle: "The Finish",
    heroSubtitle: "Clients Trust",
    heroDescription: "Trusted by discerning clients for premium residential and commercial projects. This is a demo site showing what Soullab can build for your business.",

    availabilityText: "Now accepting new projects",

    footerTagline: "Your tagline here.\nYour excellence.",
    credentials: ["Licensed & Insured", "Your Certifications"],

    badgeUrl: "/images/virtual-assistant-badge.png",
  },
};

// ═══════════════════════════════════════════════════════════════════════════════
// ACTIVE BRAND (set via BRAND_PRESET env var, defaults to 'oldhead')
// ═══════════════════════════════════════════════════════════════════════════════

const presetKey = import.meta.env.BRAND_PRESET || 'oldhead';
export const brand: BrandConfig = BRAND_PRESETS[presetKey] || BRAND_PRESETS.oldhead;

// Export for dynamic access
export const getBrand = (key: string): BrandConfig => {
  return BRAND_PRESETS[key] || BRAND_PRESETS.oldhead;
};
