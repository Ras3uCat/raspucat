import 'package:raspucat/app/data/models/plan_model.dart';

const List<PlanModel> planData = [
  PlanModel(
    id: 'pro',
    name: 'Pro',
    label: 'Launchpad',
    price: 'Starting at \$1,500',
    idealFor: 'Solopreneurs & Startups',
    features: [
      'Core Site (Hero, Services, FAQ)',
      'Blog & Gallery',
      'CRM & Lead Gen',
    ],
    isFeatured: false,
    isCustom: false,
  ),
  PlanModel(
    id: 'premium',
    name: 'Premium',
    label: 'Engine',
    price: 'Starting at \$3,500',
    idealFor: 'Service & Retail SMBs',
    features: [
      'Everything in Pro',
      'Online Booking / Shop',
      'Stripe Integration',
      'Tip / Gratuity at Checkout',
      'Web Push Notifications',
      'Monthly Stats Digest',
    ],
    isFeatured: true,
    isCustom: false,
  ),
  PlanModel(
    id: 'custom',
    name: 'Custom',
    label: 'Scale',
    price: 'Starting at \$8,500',
    idealFor: 'Franchises & High-Growth',
    features: [
      'Everything in Premium',
      'AI Chatbot (Claude-powered)',
      'Automated PDF Invoices',
      'Multi-location Support',
      'Mobile Apps (iOS/Android)',
      'Stripe Connect (Multi-staff)',
    ],
    isFeatured: false,
    isCustom: true,
  ),
];
