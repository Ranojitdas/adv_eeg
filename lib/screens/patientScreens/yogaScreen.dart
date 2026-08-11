import 'package:ADDvEEG/screens/patientScreens/eegScreen.dart';
import 'package:ADDvEEG/screens/patientScreens/yogaScreen.dart';
import 'package:ADDvEEG/screens/patientScreens/yogaPoseDetailed.dart';
import 'package:ADDvEEG/screens/patientScreens/musicPlayerScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/constants.dart';
import '../../constants/media_urls.dart';
import '../../models/patients/yogaModel.dart';
import '../../controllers/patientSideControllers/yogaController.dart';

class YogaScreen extends StatefulWidget {
  final YogaController controller = Get.put(YogaController());
  final storage = GetStorage();
  final String? initialSection;
  final String? initialPractice;

  YogaScreen({
    Key? key,
    this.initialSection,
    this.initialPractice,
  }) : super(key: key);

  @override
  State<YogaScreen> createState() => _YogaScreenState();
}

class _YogaScreenState extends State<YogaScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _sortBy = 'Default';
  final List<String> _categories = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];
  final List<String> _sortOptions = [
    'Default',
    'Duration (Short to Long)',
    'Duration (Long to Short)',
    'Difficulty'
  ];
  List<YogaPose> _recentlyViewed = [];
  List<YogaPose> _favorites = [];
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _practiceKeys = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavorites();
    _loadRecentlyViewed();
    _initializeYogaPoses();

    // Set initial tab based on initialSection
    if (widget.initialSection != null) {
      if (widget.initialSection == 'meditation') {
        _tabController.animateTo(1);
      } else if (widget.initialSection == 'music') {
        _tabController.animateTo(2);
      }
    }

    // Add post-frame callback to scroll to specific practice
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPractice != null) {
        _scrollToPractice(widget.initialPractice!);
      }
    });
  }

  void _scrollToPractice(String practiceName) {
    final key = _practiceKeys[practiceName];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _initializeYogaPoses() {
    final poses = [
      // Beginner Poses
      YogaPose(
        poseName: 'Mountain Pose',
        description:
            'A foundational standing pose that improves posture and balance',
        difficulty: 'Beginner',
        duration: 5,
        poseImage: MediaUrls.getYogaImage('Mountain Pose'),
        videoUrl: MediaUrls.getYogaVideo('Mountain Pose'),
        benefits: [
          'Improves posture',
          'Strengthens legs',
          'Increases body awareness',
          'Reduces stress'
        ],
        steps: [
          'Stand with feet together',
          'Arms at sides, palms forward',
          'Lift through crown of head',
          'Engage thigh muscles',
          'Hold for 5-10 breaths'
        ],
      ),
      YogaPose(
        poseName: 'Downward Dog',
        description: 'An energizing pose that stretches the entire body',
        difficulty: 'Beginner',
        duration: 5,
        poseImage: MediaUrls.getYogaImage('Downward Dog'),
        videoUrl: MediaUrls.getYogaVideo('Downward Dog'),
        benefits: [
          'Strengthens arms and legs',
          'Stretches shoulders and hamstrings',
          'Calms the mind',
          'Energizes the body'
        ],
        steps: [
          'Start on hands and knees',
          'Lift hips up and back',
          'Press hands into mat',
          'Straighten legs if possible',
          'Hold for 5-10 breaths'
        ],
      ),
      YogaPose(
        poseName: 'Warrior I',
        description: 'A powerful standing pose that builds strength and focus',
        difficulty: 'Beginner',
        duration: 5,
        poseImage: MediaUrls.getYogaImage('Warrior I'),
        videoUrl: MediaUrls.getYogaVideo('Warrior I'),
        benefits: [
          'Strengthens legs and core',
          'Improves balance',
          'Builds focus',
          'Increases stamina'
        ],
        steps: [
          'Step one foot back',
          'Bend front knee',
          'Square hips forward',
          'Raise arms overhead',
          'Hold for 5 breaths each side'
        ],
      ),
      YogaPose(
        poseName: 'Bridge Pose',
        description:
            'A gentle backbend that strengthens the back and opens the chest',
        difficulty: 'Beginner',
        duration: 5,
        poseImage: MediaUrls.getYogaImage('Bridge Pose'),
        videoUrl: MediaUrls.getYogaVideo('Bridge Pose'),
        benefits: [
          'Strengthens back',
          'Opens chest',
          'Reduces stress',
          'Improves posture'
        ],
        steps: [
          'Lie on back, knees bent',
          'Feet hip-width apart',
          'Lift hips toward ceiling',
          'Interlace hands under back',
          'Hold for 5-10 breaths'
        ],
      ),
      YogaPose(
        poseName: 'Seated Forward Fold',
        description: 'A calming pose that stretches the back and legs',
        difficulty: 'Beginner',
        duration: 5,
        poseImage: MediaUrls.getYogaImage('Seated Forward Fold'),
        videoUrl: MediaUrls.getYogaVideo('Seated Forward Fold'),
        benefits: [
          'Stretches back and legs',
          'Calms the mind',
          'Reduces stress',
          'Improves flexibility'
        ],
        steps: [
          'Sit with legs extended',
          'Fold forward from hips',
          'Hold feet or ankles',
          'Relax head and neck',
          'Hold for 5-10 breaths'
        ],
      ),
      // Intermediate Poses
      YogaPose(
        poseName: 'Crow Pose',
        description: 'An arm balance that builds strength and focus',
        difficulty: 'Intermediate',
        duration: 5,
        poseImage: MediaUrls.getYogaImage('Crow Pose'),
        videoUrl: MediaUrls.getYogaVideo('Crow Pose'),
        benefits: [
          'Strengthens arms and core',
          'Improves balance',
          'Builds focus',
          'Increases confidence'
        ],
        steps: [
          'Squat with feet together',
          'Place hands shoulder-width apart',
          'Bend elbows slightly',
          'Lift hips and shift weight forward',
          'Hold for 5 breaths'
        ],
      ),
      YogaPose(
        poseName: 'Wheel Pose',
        description: 'A deep backbend that opens the chest and shoulders',
        difficulty: 'Intermediate',
        duration: 5,
        poseImage: MediaUrls.getYogaImage('Wheel Pose'),
        videoUrl: MediaUrls.getYogaVideo('Wheel Pose'),
        benefits: [
          'Opens chest and shoulders',
          'Strengthens back',
          'Increases energy',
          'Improves flexibility'
        ],
        steps: [
          'Lie on back, knees bent',
          'Place hands by ears',
          'Press into hands and feet',
          'Lift hips toward ceiling',
          'Hold for 5 breaths'
        ],
      ),
      YogaPose(
        poseName: 'Headstand',
        description: 'An inversion that builds strength and focus',
        difficulty: 'Intermediate',
        duration: 5,
        poseImage: MediaUrls.getYogaImage('Headstand'),
        videoUrl: MediaUrls.getYogaVideo('Headstand'),
        benefits: [
          'Strengthens arms and core',
          'Improves balance',
          'Increases focus',
          'Calms the mind'
        ],
        steps: [
          'Interlace fingers on mat',
          'Place crown of head on mat',
          'Lift hips and walk feet in',
          'Lift legs toward ceiling',
          'Hold for 5-10 breaths'
        ],
      ),
      YogaPose(
        poseName: 'King Pigeon',
        description: 'A deep hip opener that improves flexibility',
        difficulty: 'Intermediate',
        duration: 5,
        poseImage: MediaUrls.getYogaImage('King Pigeon'),
        videoUrl: MediaUrls.getYogaVideo('King Pigeon'),
        benefits: [
          'Opens hips',
          'Stretches thighs',
          'Improves posture',
          'Reduces stress'
        ],
        steps: [
          'Start in downward dog',
          'Bring one knee forward',
          'Lower back leg to mat',
          'Square hips forward',
          'Hold for 5 breaths each side'
        ],
      ),
      YogaPose(
        poseName: 'Firefly Pose',
        description: 'An arm balance that requires strength and flexibility',
        difficulty: 'Intermediate',
        duration: 5,
        poseImage: MediaUrls.getYogaImage('Firefly Pose'),
        videoUrl: MediaUrls.getYogaVideo('Firefly Pose'),
        benefits: [
          'Strengthens arms and core',
          'Improves balance',
          'Opens hips',
          'Builds focus'
        ],
        steps: [
          'Squat with feet wide',
          'Place hands between legs',
          'Lift hips and shift weight forward',
          'Straighten legs to sides',
          'Hold for 5 breaths'
        ],
      ),
      YogaPose(
        poseName: 'Eight-Angle Pose',
        description: 'An advanced arm balance that builds strength',
        difficulty: 'Intermediate',
        duration: 5,
        poseImage: MediaUrls.getYogaImage('Eight-Angle Pose'),
        videoUrl: MediaUrls.getYogaVideo('Eight-Angle Pose'),
        benefits: [
          'Strengthens arms and core',
          'Improves balance',
          'Builds focus',
          'Increases confidence'
        ],
        steps: [
          'Start in crow pose',
          'Twist torso to one side',
          'Extend legs to side',
          'Keep arms straight',
          'Hold for 5 breaths each side'
        ],
      ),
    ];

    // Only add poses that don't already exist
    final newPoses = poses
        .where((newPose) => !widget.controller.yogaPoses
            .any((existingPose) => existingPose.poseName == newPose.poseName))
        .toList();

    widget.controller.updateYogaPoses(newPoses);
  }

  void _loadFavorites() {
    final favorites =
        widget.storage.read<List<dynamic>>('favorite_poses') ?? [];
    _favorites = widget.controller.yogaPoses
        .where((pose) => favorites.any((f) => f.toString() == pose.poseName))
        .toList();
  }

  void _loadRecentlyViewed() {
    final recent = widget.storage.read<List<dynamic>>('recent_poses') ?? [];
    _recentlyViewed = widget.controller.yogaPoses
        .where((pose) => recent.any((r) => r.toString() == pose.poseName))
        .toList();
  }

  void _toggleFavorite(YogaPose pose) {
    setState(() {
      if (_favorites.any((p) => p.poseName == pose.poseName)) {
        _favorites.removeWhere((p) => p.poseName == pose.poseName);
        widget.storage.write(
            'favorite_poses', _favorites.map((p) => p.poseName).toList());
      } else {
        _favorites.add(pose);
        widget.storage.write(
            'favorite_poses', _favorites.map((p) => p.poseName).toList());
      }
    });
  }

  void _addToRecentlyViewed(YogaPose pose) {
    setState(() {
      if (!_recentlyViewed.any((p) => p.poseName == pose.poseName)) {
        _recentlyViewed.insert(0, pose);
        if (_recentlyViewed.length > 5) {
          _recentlyViewed.removeLast();
        }
        widget.storage.write(
            'recent_poses', _recentlyViewed.map((p) => p.poseName).toList());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(
                    'Wellness Center',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: YogaPoseSearchDelegate(
                              widget.controller.yogaPoses),
                        );
                      },
                    ),
                  ],
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF4B4949),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Meditation'),
                    Tab(text: 'Yoga'),
                    Tab(text: 'Music'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMeditationTab(),
                _buildYogaTab(),
                _buildMusicTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYogaTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, top: 10),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0850FD)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0850FD)
                                : Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.health_and_safety,
                          color: Color(0xFF0850FD)),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Wellness Tips',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWellnessTip(
                    'Stay Hydrated',
                    'Drink at least 8 glasses of water daily',
                    Icons.water_drop,
                  ),
                  const SizedBox(height: 12),
                  _buildWellnessTip(
                    'Mindful Breathing',
                    'Take 5 deep breaths whenever you feel stressed',
                    Icons.air,
                  ),
                  const SizedBox(height: 12),
                  _buildWellnessTip(
                    'Regular Exercise',
                    'Aim for 30 minutes of physical activity daily',
                    Icons.fitness_center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_recentlyViewed.isNotEmpty) ...[
              Text(
                'Recently Viewed',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentlyViewed.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _buildRecentPoseCard(_recentlyViewed[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'All Poses',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildYogaPoseGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessTip(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0850FD).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF0850FD), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMeditationCard(
              'Mindful Breathing',
              'Focus on your breath to calm the mind',
              Icons.air_rounded,
              Colors.blue,
              MediaUrls.getMeditationVideo('Mindful Breathing'),
            ),
            const SizedBox(height: 16),
            _buildMeditationCard(
              'Body Scan',
              'Release tension through body awareness',
              Icons.self_improvement_rounded,
              Colors.purple,
              MediaUrls.getMeditationVideo('Body Scan'),
            ),
            const SizedBox(height: 16),
            _buildMeditationCard(
              'Loving Kindness',
              'Cultivate compassion and positive emotions',
              Icons.favorite_rounded,
              Colors.red,
              MediaUrls.getMeditationVideo('Loving Kindness'),
            ),
            const SizedBox(height: 16),
            _buildMeditationCard(
              'Walking Meditation',
              'Mindful movement for stress relief',
              Icons.directions_walk_rounded,
              Colors.green,
              MediaUrls.getMeditationVideo('Walking Meditation'),
            ),
            const SizedBox(height: 16),
            _buildMeditationCard(
              'Gratitude Practice',
              'Focus on positive aspects of life',
              Icons.emoji_emotions_rounded,
              Colors.orange,
              MediaUrls.getMeditationVideo('Gratitude Practice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMusicCard(
              'Calming Nature Sounds',
              'Forest, Ocean, Rain',
              Icons.nature_rounded,
              Colors.green,
              MediaUrls.getMusicVideo('Calming Nature Sounds'),
            ),
            const SizedBox(height: 16),
            _buildMusicCard(
              'Meditation Music',
              'Zen, Tibetan Bowls',
              Icons.self_improvement_rounded,
              Colors.blue,
              MediaUrls.getMusicVideo('Meditation Music'),
            ),
            const SizedBox(height: 16),
            _buildMusicCard(
              'Sleep Music',
              'Lullabies, White Noise',
              Icons.nightlight_round,
              Colors.purple,
              MediaUrls.getMusicVideo('Sleep Music'),
            ),
            const SizedBox(height: 16),
            _buildMusicCard(
              'Stress Relief',
              'Soft Piano, Ambient',
              Icons.piano_rounded,
              Colors.orange,
              MediaUrls.getMusicVideo('Stress Relief'),
            ),
            const SizedBox(height: 16),
            _buildMusicCard(
              'Focus & Concentration',
              'Binaural Beats, Lo-fi',
              Icons.headphones_rounded,
              Colors.teal,
              MediaUrls.getMusicVideo('Focus & Concentration'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeditationCard(
    String title,
    String description,
    IconData icon,
    Color color,
    String videoUrl,
  ) {
    return GestureDetector(
      onTap: () {
        Get.to(() => MusicPlayerScreen(
              title: title,
              videoUrl: videoUrl,
            ));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_filled,
              color: color,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPoseCard(YogaPose pose) {
    return GestureDetector(
      onTap: () {
        _addToRecentlyViewed(pose);
        Get.to(() => YogaPoseDetailScreen(yogaPose: pose));
      },
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: pose.poseImage,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 100,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 100,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pose.poseName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pose.difficulty,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF0850FD),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${pose.duration} min',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String videoUrl,
  ) {
    return GestureDetector(
      onTap: () {
        Get.to(() => MusicPlayerScreen(
              title: title,
              videoUrl: videoUrl,
            ));
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Stack(
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: _getMusicImage(title),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            // Overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Play Now',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMusicImage(String title) {
    return MediaUrls.getMusicImage(title);
  }

  Widget _buildYogaPoseGrid() {
    var poses = widget.controller.yogaPoses;

    // Apply category filter
    if (_selectedCategory != 'All') {
      if (_selectedCategory == 'Beginner') {
        poses = [
          YogaPose(
            poseName: 'Mountain Pose',
            description:
                'A foundational standing pose that improves posture and balance',
            difficulty: 'Beginner',
            duration: 5,
            poseImage: MediaUrls.getYogaImage('Mountain Pose'),
            videoUrl: MediaUrls.getYogaVideo('Mountain Pose'),
            benefits: [
              'Improves posture',
              'Strengthens legs',
              'Increases body awareness',
              'Reduces stress'
            ],
            steps: [
              'Stand with feet together',
              'Arms at sides, palms forward',
              'Lift through crown of head',
              'Engage thigh muscles',
              'Hold for 5-10 breaths'
            ],
          ),
          YogaPose(
            poseName: 'Downward Dog',
            description: 'An energizing pose that stretches the entire body',
            difficulty: 'Beginner',
            duration: 5,
            poseImage: MediaUrls.getYogaImage('Downward Dog'),
            videoUrl: MediaUrls.getYogaVideo('Downward Dog'),
            benefits: [
              'Strengthens arms and legs',
              'Stretches shoulders and hamstrings',
              'Calms the mind',
              'Energizes the body'
            ],
            steps: [
              'Start on hands and knees',
              'Lift hips up and back',
              'Press hands into mat',
              'Straighten legs if possible',
              'Hold for 5-10 breaths'
            ],
          ),
          YogaPose(
            poseName: 'Warrior I',
            description:
                'A powerful standing pose that builds strength and focus',
            difficulty: 'Beginner',
            duration: 5,
            poseImage: MediaUrls.getYogaImage('Warrior I'),
            videoUrl: MediaUrls.getYogaVideo('Warrior I'),
            benefits: [
              'Strengthens legs and core',
              'Improves balance',
              'Builds focus',
              'Increases stamina'
            ],
            steps: [
              'Step one foot back',
              'Bend front knee',
              'Square hips forward',
              'Raise arms overhead',
              'Hold for 5 breaths each side'
            ],
          ),
          YogaPose(
            poseName: 'Bridge Pose',
            description:
                'A gentle backbend that strengthens the back and opens the chest',
            difficulty: 'Beginner',
            duration: 5,
            poseImage: MediaUrls.getYogaImage('Bridge Pose'),
            videoUrl: MediaUrls.getYogaVideo('Bridge Pose'),
            benefits: [
              'Strengthens back',
              'Opens chest',
              'Reduces stress',
              'Improves posture'
            ],
            steps: [
              'Lie on back, knees bent',
              'Feet hip-width apart',
              'Lift hips toward ceiling',
              'Interlace hands under back',
              'Hold for 5-10 breaths'
            ],
          ),
          YogaPose(
            poseName: 'Seated Forward Fold',
            description: 'A calming pose that stretches the back and legs',
            difficulty: 'Beginner',
            duration: 5,
            poseImage: MediaUrls.getYogaImage('Seated Forward Fold'),
            videoUrl: MediaUrls.getYogaVideo('Seated Forward Fold'),
            benefits: [
              'Stretches back and legs',
              'Calms the mind',
              'Reduces stress',
              'Improves flexibility'
            ],
            steps: [
              'Sit with legs extended',
              'Fold forward from hips',
              'Hold feet or ankles',
              'Relax head and neck',
              'Hold for 5-10 breaths'
            ],
          ),
        ];
      } else if (_selectedCategory == 'Intermediate') {
        poses = [
          YogaPose(
            poseName: 'Crow Pose',
            description: 'An arm balance that builds strength and focus',
            difficulty: 'Intermediate',
            duration: 5,
            poseImage: MediaUrls.getYogaImage('Crow Pose'),
            videoUrl: MediaUrls.getYogaVideo('Crow Pose'),
            benefits: [
              'Strengthens arms and core',
              'Improves balance',
              'Builds focus',
              'Increases confidence'
            ],
            steps: [
              'Squat with feet together',
              'Place hands shoulder-width apart',
              'Bend elbows slightly',
              'Lift hips and shift weight forward',
              'Hold for 5 breaths'
            ],
          ),
          YogaPose(
            poseName: 'Wheel Pose',
            description: 'A deep backbend that opens the chest and shoulders',
            difficulty: 'Intermediate',
            duration: 5,
            poseImage: MediaUrls.getYogaImage('Wheel Pose'),
            videoUrl: MediaUrls.getYogaVideo('Wheel Pose'),
            benefits: [
              'Opens chest and shoulders',
              'Strengthens back',
              'Increases energy',
              'Improves flexibility'
            ],
            steps: [
              'Lie on back, knees bent',
              'Place hands by ears',
              'Press into hands and feet',
              'Lift hips toward ceiling',
              'Hold for 5 breaths'
            ],
          ),
          YogaPose(
            poseName: 'Headstand',
            description: 'An inversion that builds strength and focus',
            difficulty: 'Intermediate',
            duration: 5,
            poseImage: MediaUrls.getYogaImage('Headstand'),
            videoUrl: MediaUrls.getYogaVideo('Headstand'),
            benefits: [
              'Strengthens arms and core',
              'Improves balance',
              'Increases focus',
              'Calms the mind'
            ],
            steps: [
              'Interlace fingers on mat',
              'Place crown of head on mat',
              'Lift hips and walk feet in',
              'Lift legs toward ceiling',
              'Hold for 5-10 breaths'
            ],
          ),
          YogaPose(
            poseName: 'King Pigeon',
            description: 'A deep hip opener that improves flexibility',
            difficulty: 'Intermediate',
            duration: 5,
            poseImage: MediaUrls.getYogaImage('King Pigeon'),
            videoUrl: MediaUrls.getYogaVideo('King Pigeon'),
            benefits: [
              'Opens hips',
              'Stretches thighs',
              'Improves posture',
              'Reduces stress'
            ],
            steps: [
              'Start in downward dog',
              'Bring one knee forward',
              'Lower back leg to mat',
              'Square hips forward',
              'Hold for 5 breaths each side'
            ],
          ),
          YogaPose(
            poseName: 'Firefly Pose',
            description:
                'An arm balance that requires strength and flexibility',
            difficulty: 'Intermediate',
            duration: 5,
            poseImage: MediaUrls.getYogaImage('Firefly Pose'),
            videoUrl: MediaUrls.getYogaVideo('Firefly Pose'),
            benefits: [
              'Strengthens arms and core',
              'Improves balance',
              'Opens hips',
              'Builds focus'
            ],
            steps: [
              'Squat with feet wide',
              'Place hands between legs',
              'Lift hips and shift weight forward',
              'Straighten legs to sides',
              'Hold for 5 breaths'
            ],
          ),
          YogaPose(
            poseName: 'Eight-Angle Pose',
            description: 'An advanced arm balance that builds strength',
            difficulty: 'Intermediate',
            duration: 5,
            poseImage: MediaUrls.getYogaImage('Eight-Angle Pose'),
            videoUrl: MediaUrls.getYogaVideo('Eight-Angle Pose'),
            benefits: [
              'Strengthens arms and core',
              'Improves balance',
              'Builds focus',
              'Increases confidence'
            ],
            steps: [
              'Start in crow pose',
              'Twist torso to one side',
              'Extend legs to side',
              'Keep arms straight',
              'Hold for 5 breaths each side'
            ],
          ),
        ];
      } else if (_selectedCategory == 'Advanced') {
        poses = [
          YogaPose(
            poseName: 'Scorpion Pose',
            description: 'An advanced inversion requiring exceptional strength and flexibility',
            difficulty: 'Advanced',
            duration: 8,
            poseImage: MediaUrls.getYogaImage('Scorpion Pose'),
            videoUrl: MediaUrls.getYogaVideo('Scorpion Pose'),
            benefits: [
              'Builds extreme core strength',
              'Improves spinal flexibility',
              'Enhances balance and focus',
              'Increases confidence'
            ],
            steps: [
              'Start in forearm stand',
              'Slowly bend knees toward head',
              'Arch back deeply',
              'Touch feet to head if possible',
              'Hold for 3-5 breaths'
            ],
          ),
          YogaPose(
            poseName: 'Flying Pigeon',
            description: 'Advanced arm balance combining strength with hip flexibility',
            difficulty: 'Advanced',
            duration: 6,
            poseImage: MediaUrls.getYogaImage('Flying Pigeon'),
            videoUrl: MediaUrls.getYogaVideo('Flying Pigeon'),
            benefits: [
              'Strengthens arms and core',
              'Opens hip flexors',
              'Improves balance',
              'Builds mental focus'
            ],
            steps: [
              'Start in crow pose',
              'Extend one leg back',
              'Keep arms strong',
              'Maintain steady breathing',
              'Hold for 5 breaths each side'
            ],
          ),
          YogaPose(
            poseName: 'Handstand',
            description: 'Ultimate inversion requiring full-body strength and control',
            difficulty: 'Advanced',
            duration: 10,
            poseImage: MediaUrls.getYogaImage('Handstand'),
            videoUrl: MediaUrls.getYogaVideo('Handstand'),
            benefits: [
              'Builds shoulder and arm strength',
              'Improves circulation',
              'Enhances focus and determination',
              'Boosts confidence'
            ],
            steps: [
              'Start in downward dog',
              'Walk feet closer to hands',
              'Lift one leg, then both',
              'Keep core engaged',
              'Hold for 10-30 seconds'
            ],
          ),
          YogaPose(
            poseName: 'King Dancer',
            description: 'Advanced backbend requiring exceptional balance and flexibility',
            difficulty: 'Advanced',
            duration: 7,
            poseImage: MediaUrls.getYogaImage('King Dancer'),
            videoUrl: MediaUrls.getYogaVideo('King Dancer'),
            benefits: [
              'Opens chest and shoulders',
              'Strengthens legs',
              'Improves balance',
              'Increases spinal flexibility'
            ],
            steps: [
              'Stand on one leg',
              'Bend back leg and grab foot',
              'Lift foot toward head',
              'Reach other arm forward',
              'Hold for 5 breaths each side'
            ],
          ),
        ];
      } else if (_selectedCategory == 'Meditation') {
        poses = [
          YogaPose(
            poseName: 'Mindful Breathing Meditation',
            description:
                'A simple yet powerful meditation technique focusing on breath awareness',
            difficulty: 'Beginner',
            duration: 10,
            poseImage: MediaUrls.getMeditationImage('Mindful Breathing'),
            videoUrl: MediaUrls.getMeditationVideo('Mindful Breathing'),
            benefits: [
              'Reduces stress and anxiety',
              'Improves focus and concentration',
              'Promotes emotional well-being',
              'Enhances self-awareness'
            ],
            steps: [
              'Find a quiet, comfortable place to sit',
              'Close your eyes and take deep breaths',
              'Focus on the sensation of your breath',
              'When your mind wanders, gently bring it back to your breath',
              'Continue for 5-10 minutes'
            ],
          ),
          YogaPose(
            poseName: 'Body Scan Meditation',
            description:
                'A guided meditation that helps you connect with your body and release tension',
            difficulty: 'Beginner',
            duration: 15,
            poseImage: MediaUrls.getMeditationImage('Body Scan'),
            videoUrl: MediaUrls.getMeditationVideo('Body Scan'),
            benefits: [
              'Reduces physical tension',
              'Improves body awareness',
              'Promotes relaxation',
              'Helps with sleep'
            ],
            steps: [
              'Lie down in a comfortable position',
              'Close your eyes and take deep breaths',
              'Focus on each part of your body, starting from toes',
              'Notice any tension and consciously release it',
              'Move slowly up through your body'
            ],
          ),
          YogaPose(
            poseName: 'Loving Kindness Meditation',
            description:
                'Cultivate compassion and positive emotions through guided meditation',
            difficulty: 'Beginner',
            duration: 12,
            poseImage: MediaUrls.getMeditationImage('Loving Kindness'),
            videoUrl: MediaUrls.getMeditationVideo('Loving Kindness'),
            benefits: [
              'Increases compassion',
              'Reduces negative emotions',
              'Improves relationships',
              'Enhances emotional well-being'
            ],
            steps: [
              'Sit comfortably with eyes closed',
              'Focus on your breath',
              'Send loving thoughts to yourself',
              'Extend these thoughts to others',
              'Practice for 10-15 minutes'
            ],
          ),
          YogaPose(
            poseName: 'Walking Meditation',
            description:
                'Mindful movement meditation for stress relief and awareness',
            difficulty: 'Beginner',
            duration: 15,
            poseImage: MediaUrls.getMeditationImage('Walking Meditation'),
            videoUrl: MediaUrls.getMeditationVideo('Walking Meditation'),
            benefits: [
              'Combines movement with mindfulness',
              'Reduces stress and anxiety',
              'Improves focus',
              'Enhances body awareness'
            ],
            steps: [
              'Find a quiet path or space',
              'Walk slowly and deliberately',
              'Focus on each step and movement',
              'Maintain awareness of your breath',
              'Practice for 10-15 minutes'
            ],
          ),
          YogaPose(
            poseName: 'Gratitude Meditation',
            description:
                'Focus on positive aspects of life through guided meditation',
            difficulty: 'Beginner',
            duration: 10,
            poseImage: MediaUrls.getMeditationImage('Gratitude Practice'),
            videoUrl: MediaUrls.getMeditationVideo('Gratitude Practice'),
            benefits: [
              'Increases positive emotions',
              'Reduces stress',
              'Improves sleep',
              'Enhances overall well-being'
            ],
            steps: [
              'Find a quiet space to sit',
              'Close your eyes and breathe deeply',
              'Reflect on things you are grateful for',
              'Express gratitude in your mind',
              'Continue for 5-10 minutes'
            ],
          ),
        ];
      } else if (_selectedCategory == 'Breathing') {
        poses = [
          YogaPose(
            poseName: '4-7-8 Breathing Technique',
            description:
                'A powerful breathing pattern that helps reduce anxiety and promote sleep',
            difficulty: 'Beginner',
            duration: 5,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=gz4G31LGyog',
            benefits: [
              'Reduces anxiety',
              'Helps with sleep',
              'Manages stress',
              'Improves focus'
            ],
            steps: [
              'Inhale through nose for 4 counts',
              'Hold breath for 7 counts',
              'Exhale through mouth for 8 counts',
              'Repeat 4 times',
              'Practice 2-3 times daily'
            ],
          ),
          YogaPose(
            poseName: 'Alternate Nostril Breathing',
            description:
                'A balancing breathing technique that calms the mind and reduces stress',
            difficulty: 'Intermediate',
            duration: 8,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=YwYDjQdQ_sk',
            benefits: [
              'Balances left and right brain',
              'Reduces stress and anxiety',
              'Improves focus',
              'Promotes mental clarity'
            ],
            steps: [
              'Sit in a comfortable position',
              'Close right nostril, inhale through left',
              'Close left nostril, exhale through right',
              'Inhale through right, exhale through left',
              'Continue for 5-10 minutes'
            ],
          ),
          YogaPose(
            poseName: 'Box Breathing',
            description:
                'A simple yet effective breathing technique for stress management',
            difficulty: 'Beginner',
            duration: 5,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            benefits: [
              'Reduces stress',
              'Improves focus',
              'Calms the mind',
              'Enhances emotional control'
            ],
            steps: [
              'Inhale for 4 counts',
              'Hold for 4 counts',
              'Exhale for 4 counts',
              'Hold for 4 counts',
              'Repeat for 5 minutes'
            ],
          ),
          YogaPose(
            poseName: 'Deep Belly Breathing',
            description:
                'A fundamental breathing technique for relaxation and stress relief',
            difficulty: 'Beginner',
            duration: 5,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            benefits: [
              'Reduces stress',
              'Improves oxygen flow',
              'Calms the nervous system',
              'Enhances relaxation'
            ],
            steps: [
              'Lie down or sit comfortably',
              'Place hand on belly',
              'Breathe deeply into belly',
              'Feel belly rise and fall',
              'Practice for 5 minutes'
            ],
          ),
          YogaPose(
            poseName: 'Ocean Breath',
            description:
                'A calming breathing technique that mimics ocean waves',
            difficulty: 'Intermediate',
            duration: 8,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            benefits: [
              'Calms the mind',
              'Reduces anxiety',
              'Improves focus',
              'Enhances meditation practice'
            ],
            steps: [
              'Sit in a comfortable position',
              'Constrict back of throat',
              'Breathe through nose',
              'Create ocean-like sound',
              'Practice for 5-8 minutes'
            ],
          ),
        ];
      } else if (_selectedCategory == 'Stress Relief') {
        poses = [
          YogaPose(
            poseName: 'Child\'s Pose',
            description:
                'A gentle resting pose that helps release tension and calm the mind',
            difficulty: 'Beginner',
            duration: 5,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=2MJGg-dUKh0',
            benefits: [
              'Relieves stress and anxiety',
              'Calms the mind',
              'Stretches back and hips',
              'Promotes relaxation'
            ],
            steps: [
              'Kneel on the floor',
              'Touch big toes together',
              'Sit back on heels',
              'Fold forward, arms extended',
              'Rest forehead on floor'
            ],
          ),
          YogaPose(
            poseName: 'Legs Up the Wall',
            description:
                'A restorative pose that helps reduce stress and improve circulation',
            difficulty: 'Beginner',
            duration: 10,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=ZBhJCjOSGFY',
            benefits: [
              'Reduces stress and anxiety',
              'Improves circulation',
              'Relieves tired legs',
              'Calms the nervous system'
            ],
            steps: [
              'Sit close to a wall',
              'Lie back and swing legs up',
              'Rest arms by sides',
              'Close eyes and breathe deeply',
              'Stay for 5-10 minutes'
            ],
          ),
          YogaPose(
            poseName: 'Cat-Cow Stretch',
            description:
                'A gentle flowing movement that relieves tension in the spine',
            difficulty: 'Beginner',
            duration: 5,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            benefits: [
              'Relieves back tension',
              'Improves spine flexibility',
              'Reduces stress',
              'Calms the mind'
            ],
            steps: [
              'Start on hands and knees',
              'Arch back like a cat',
              'Drop belly like a cow',
              'Flow with breath',
              'Repeat 5-10 times'
            ],
          ),
          YogaPose(
            poseName: 'Forward Fold',
            description:
                'A calming pose that helps release tension in the back and neck',
            difficulty: 'Beginner',
            duration: 5,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            benefits: [
              'Relieves stress',
              'Calms the mind',
              'Stretches back and legs',
              'Improves circulation'
            ],
            steps: [
              'Stand with feet hip-width apart',
              'Fold forward from hips',
              'Let head hang heavy',
              'Bend knees if needed',
              'Hold for 5 breaths'
            ],
          ),
          YogaPose(
            poseName: 'Seated Twist',
            description:
                'A gentle twisting pose that helps release tension in the spine',
            difficulty: 'Beginner',
            duration: 5,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            benefits: [
              'Relieves back tension',
              'Improves digestion',
              'Reduces stress',
              'Enhances spinal mobility'
            ],
            steps: [
              'Sit with legs extended',
              'Cross right foot over left knee',
              'Twist to the right',
              'Hold for 5 breaths',
              'Repeat on other side'
            ],
          ),
        ];
      } else if (_selectedCategory == 'Sleep') {
        poses = [
          YogaPose(
            poseName: 'Reclining Butterfly',
            description:
                'A gentle pose that helps prepare the body and mind for sleep',
            difficulty: 'Beginner',
            duration: 8,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=ZBhJCjOSGFY',
            benefits: [
              'Promotes better sleep',
              'Reduces anxiety',
              'Relieves tension',
              'Calms the mind'
            ],
            steps: [
              'Lie on your back',
              'Bring soles of feet together',
              'Let knees fall out to sides',
              'Place arms by sides',
              'Breathe deeply for 5-8 minutes'
            ],
          ),
          YogaPose(
            poseName: 'Corpse Pose',
            description: 'A final relaxation pose that helps prepare for sleep',
            difficulty: 'Beginner',
            duration: 10,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=ZBhJCjOSGFY',
            benefits: [
              'Deep relaxation',
              'Reduces insomnia',
              'Calms the mind',
              'Relieves stress'
            ],
            steps: [
              'Lie on your back',
              'Arms slightly away from body',
              'Palms facing up',
              'Close your eyes',
              'Breathe naturally for 10 minutes'
            ],
          ),
          YogaPose(
            poseName: 'Legs on Chair',
            description: 'A restorative pose that helps prepare for sleep',
            difficulty: 'Beginner',
            duration: 8,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            benefits: [
              'Promotes sleep',
              'Reduces anxiety',
              'Relieves leg tension',
              'Calms the mind'
            ],
            steps: [
              'Place chair near wall',
              'Lie on back with legs on chair',
              'Support head if needed',
              'Close eyes and breathe',
              'Stay for 5-8 minutes'
            ],
          ),
          YogaPose(
            poseName: 'Supported Bridge',
            description: 'A gentle backbend that helps prepare for sleep',
            difficulty: 'Beginner',
            duration: 5,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            benefits: [
              'Relieves back tension',
              'Promotes sleep',
              'Reduces anxiety',
              'Calms the mind'
            ],
            steps: [
              'Lie on back with knees bent',
              'Place block under hips',
              'Extend legs if comfortable',
              'Close eyes and breathe',
              'Stay for 5 minutes'
            ],
          ),
          YogaPose(
            poseName: 'Seated Forward Bend',
            description: 'A calming pose that helps prepare for sleep',
            difficulty: 'Beginner',
            duration: 5,
            poseImage:
                'https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0',
            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            benefits: [
              'Calms the mind',
              'Reduces anxiety',
              'Stretches back and legs',
              'Promotes sleep'
            ],
            steps: [
              'Sit with legs extended',
              'Fold forward from hips',
              'Hold feet or ankles',
              'Relax head and neck',
              'Stay for 5 minutes'
            ],
          ),
        ];
      } else {
        poses = poses
            .where((pose) => pose.difficulty == _selectedCategory)
            .toList();
      }
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Duration (Short to Long)':
        poses.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 'Duration (Long to Short)':
        poses.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      case 'Difficulty':
        poses.sort((a, b) => _getDifficultyLevel(a.difficulty)
            .compareTo(_getDifficultyLevel(b.difficulty)));
        break;
    }

    return Column(
      children: [
        // Sort Options
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.sort, color: Colors.white.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: 8),
              Text(
                'Sort by:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    items: _sortOptions.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _sortBy = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: poses.length,
          itemBuilder: (context, index) {
            return YogaPoseCard(
              yogaPose: poses[index],
              index: index,
              isFavorite:
                  _favorites.any((p) => p.poseName == poses[index].poseName),
              onFavoriteToggle: _toggleFavorite,
              onView: _addToRecentlyViewed,
            );
          },
        ),
      ],
    );
  }

  int _getDifficultyLevel(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return 1;
      case 'Intermediate':
        return 2;
      case 'Advanced':
        return 3;
      default:
        return 0;
    }
  }
}

class YogaPoseSearchDelegate extends SearchDelegate<YogaPose> {
  final List<YogaPose> yogaPoses;

  YogaPoseSearchDelegate(this.yogaPoses);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, yogaPoses.first);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = yogaPoses
        .where(
            (pose) => pose.poseName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return _buildSearchResults(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = yogaPoses
        .where(
            (pose) => pose.poseName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return _buildSearchResults(suggestions);
  }

  Widget _buildSearchResults(List<YogaPose> results) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final pose = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(pose.poseImage),
          ),
          title: Text(pose.poseName),
          subtitle: Text(pose.description),
          onTap: () {
            Get.to(() => YogaPoseDetailScreen(yogaPose: pose));
          },
        );
      },
    );
  }
}

class YogaPoseCard extends StatelessWidget {
  final YogaPose yogaPose;
  final int index;
  final bool isFavorite;
  final Function(YogaPose) onFavoriteToggle;
  final Function(YogaPose) onView;

  const YogaPoseCard({
    Key? key,
    required this.yogaPose,
    required this.index,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onView(yogaPose);
          Get.to(() => YogaPoseDetailScreen(yogaPose: yogaPose));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: yogaPose.poseImage,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheKey: null, // Disable caching to force fresh image loads
                      placeholder: (context, url) {
                        print('🖼️ [IMAGE] Loading: ${yogaPose.poseName} - URL: ${yogaPose.poseImage}');
                        return Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorWidget: (context, url, error) {
                        print('❌ [IMAGE] Error loading ${yogaPose.poseName}: $error');
                        return Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                        );
                      },
                      imageBuilder: (context, imageProvider) {
                        print('✅ [IMAGE] Successfully loaded: ${yogaPose.poseName}');
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? Colors.red
                            : Colors.white.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      onPressed: () {
                        onFavoriteToggle(yogaPose);
                      },
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              yogaPose.poseName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              yogaPose.description,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            if (yogaPose.benefits.isNotEmpty && MediaQuery.of(context).size.width > 600)
                              Flexible(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: yogaPose.benefits.take(2).map((benefit) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.green.withValues(alpha: 0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        benefit,
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          color: Colors.green.shade300,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0850FD).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              yogaPose.difficulty,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF0850FD),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${yogaPose.duration} min',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
