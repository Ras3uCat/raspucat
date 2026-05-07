import 'package:raspucat/utils/constants/exports.dart';

class EData {
  EData._();

  static final List<ProjectModel> projects = [
    ProjectModel(
      title: 'Raspucat',
      description: 'My personal website and portfolio.',
      technologies: ['Flutter', 'GetX'],
      githubUrl: 'https://github.com/rmr32/raspucat',
      liveUrl: 'https://raspucat.com',
      imagePaths: [
        'assets/images/logos/raspucat_gradient.png',
        // 'assets/images/logos/raspucat_black.svg',
        // 'assets/images/logos/raspucat_white.svg',
      ],
    ),
    ProjectModel(
      title: 'Dashing Beard Co',
      description: 'Frontend development for a product-based business with custom animations.',
      technologies: ['HTML', 'SCSS', 'JavaScript'],
      githubUrl: 'https://github.com/rmr32/Dashing_Beard_Co',
      liveUrl: 'https://dashingbeardco.com',
      imagePaths: [
        'assets/images/projects/dashing_beard_co_hero.gif',
        // Removed: file size exceeded GitHub LFS limit
        'assets/images/projects/dashing_beard_co.png',
      ],
    ),
    ProjectModel(
      title: 'Red Dot Entertainment',
      description:
          'A full-stack booking application with user authentication, payment processing, and real-time booking management.',
      technologies: ['Flutter', 'GetX', 'Firebase', 'Stripe'],
      // githubUrl: 'https://github.com/yourusername/ecommerce',
      liveUrl: 'https://reddotentertainment.com',
      imagePaths: [
        'assets/images/projects/red_dot_entertainment_hero.gif',
        'assets/images/projects/red_dot_entertainment_book_session.png',
        'assets/images/projects/red_dot_entertainment_beats.png',
        'assets/images/projects/red_dot_entertainment_hero.png',
      ],
    ),
    ProjectModel(
      title: 'BingeQuest',
      description:
          'Cross-platform watchlist app for movies and TV shows with Queue Health scoring, mood-based filtering, AI-powered recommendations, and streaming service tracking.',
      technologies: ['Flutter', 'GetX', 'Supabase', 'Firebase'],
      liveUrl: 'https://bingequest.app',
      playStoreUrl: 'https://play.google.com/store/apps/details?id=com.ras3ucat.binge_quest',
      appStoreUrl: 'https://apps.apple.com/eg/app/bingequest/id6759207637',
      type: ProjectType.app,
      imagePaths: [
        'assets/images/projects/bingequest_play_2.png',
        'assets/images/projects/bingequest_play_3.png',
        'assets/images/projects/bingequest_ios_2.png',
        'assets/images/projects/bingequest_ios_3.png',
        'assets/images/projects/bingequest_ios_4.png',
      ],
    ),
    ProjectModel(
      title: 'DarkArc',
      description: 'Throw simulation game with realistic physics and gameplay.',
      technologies: ['Flutter', 'GetX', 'Firebase'],
      // githubUrl: 'https://github.com/yourusername/ecommerce',
      // liveUrl: 'https://reddotentertainment.com',
      imagePaths: [],
    ),
  ];
}
