import 'package:get/get.dart';

import '../../models/patients/yogaModel.dart';

class YogaController extends GetxController {
  final List<YogaPose> yogaPoses = [
    YogaPose(
      poseName: 'Child\'s Pose',
      poseImage:
          'https://media.istockphoto.com/id/1189331308/photo/lets-get-loose.jpg?s=612x612&w=is&k=20&c=cYGGE1kZ5IP_p6tBvlfPV3OifIA-LKaRvOagxOAD6-I=',
      description:
          'Balasana is a gentle resting pose that promotes relaxation and reduces anxiety. It helps calm the mind and provides a sense of comfort and security.',
      steps: [
        'Start on your hands and knees with your knees wider than hip-width apart.',
        'Lower your hips toward your heels as you reach your arms forward, resting your forehead on the floor.',
        'Relax your body and breathe deeply, focusing on releasing tension.',
      ],
      videoUrl: 'https://youtu.be/CI_JxcErfO0',
      difficulty: 'Beginner',
      duration: 5,
      benefits: [
        'Relieves stress and anxiety',
        'Stretches the hips, thighs, and ankles',
        'Calms the mind and body',
        'Helps with back pain',
      ],
    ),
    YogaPose(
      poseName: 'Standing Forward Bend',
      poseImage:
          'https://media.istockphoto.com/id/924163388/photo/young-woman-doing-uttanasana-exercise.jpg?s=612x612&w=is&k=20&c=Nx0-l0Ye-typh7eExNt0iNpy2aAM_1gL7h0RvLyk3kA=',
      description:
          'Uttanasana is a standing forward fold that stretches the entire back of the body, including the hamstrings and spine. It can help release tension and promote relaxation.',
      steps: [
        'Stand tall with your feet hip-width apart and your arms at your sides.',
        'Exhale and bend forward from your hips, keeping your knees slightly bent.',
        'Place your hands on the floor or grasp the back of your ankles.',
        'Relax your head, neck, and shoulders, and let gravity pull you deeper into the stretch.',
      ],
      videoUrl: 'https://youtu.be/CI_JxcErfO0',
      difficulty: 'Beginner',
      duration: 3,
      benefits: [
        'Stretches the hamstrings and calves',
        'Relieves tension in the spine',
        'Calms the mind',
        'Improves digestion',
      ],
    ),
    YogaPose(
      poseName: 'Corpse Pose',
      poseImage:
          'https://media.istockphoto.com/id/1255866081/photo/asian-woman-practice-yoga-dead-body-or-savasana-pose-with-meditation-smile-at-home-feeling-so.jpg?s=612x612&w=is&k=20&c=3_q03og4zfAY81f-AzJveFMH1y-4vuMISi1yI9rzIfs=',
      description:
          'Savasana is a relaxation pose that promotes deep rest and rejuvenation. It allows the body and mind to fully relax and release tension.',
      steps: [
        'Lie flat on your back with your legs extended and arms at your sides.',
        'Close your eyes and relax your entire body, releasing any tension.',
        'Breathe deeply and let go of any thoughts or distractions.',
        'Stay in this pose for several minutes, enjoying the state of deep relaxation.',
      ],
      videoUrl: 'https://youtu.be/CI_JxcErfO0',
      difficulty: 'Beginner',
      duration: 10,
      benefits: [
        'Reduces stress and anxiety',
        'Lowers blood pressure',
        'Improves sleep quality',
        'Promotes deep relaxation',
      ],
    ),
  ].obs;

  void updateYogaPoses(List<YogaPose> newPoses) {
    // Keep existing poses and add new ones that don't already exist
    for (var newPose in newPoses) {
      if (!yogaPoses.any((pose) => pose.poseName == newPose.poseName)) {
        yogaPoses.add(newPose);
      }
    }
  }
}
