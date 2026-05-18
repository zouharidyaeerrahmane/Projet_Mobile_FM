// ── Modèle User ────────────────────────────────────────────────────
class UserModel {
  final int     id;
  final String  fullName;
  final String  email;
  final String  role;
  final String? roomNumber;
  final String  createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.roomNumber,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id         : j['id'],
    fullName   : j['fullName']   ?? '',
    email      : j['email']      ?? '',
    role       : j['role']       ?? 'student',
    roomNumber : j['roomNumber'],
    createdAt  : j['createdAt']  ?? '',
  );

  bool get isStudent    => role == 'student';
  bool get isTechnician => role == 'technician';
  bool get isAgent      => role == 'agent';
  bool get isAdmin      => role == 'admin';
  bool get isSecurity   => role == 'security';

  String get roleLabel {
    switch (role) {
      case 'student'    : return 'Étudiant';
      case 'technician' : return 'Technicien';
      case 'agent'      : return 'Agent de direction';
      case 'admin'      : return 'Administrateur';
      case 'security'   : return 'Agent de sécurité';
      default           : return role;
    }
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

// ── Modèle NoiseReport ────────────────────────────────────────────
class NoiseReportModel {
  final int     id;
  final String  roomNumber;
  final String  neighborRoom;
  final String? floor;
  final String? block;
  final String  description;
  final String  status;
  final String? agentNote;
  final String  createdAt;
  final int     userId;
  final UserModel? user;

  const NoiseReportModel({
    required this.id,
    required this.roomNumber,
    required this.neighborRoom,
    this.floor,
    this.block,
    required this.description,
    required this.status,
    this.agentNote,
    required this.createdAt,
    required this.userId,
    this.user,
  });

  factory NoiseReportModel.fromJson(Map<String, dynamic> j) => NoiseReportModel(
    id           : j['id'],
    roomNumber   : j['roomNumber']   ?? '',
    neighborRoom : j['neighborRoom'] ?? '',
    floor        : j['floor'],
    block        : j['block'],
    description  : j['description']  ?? '',
    status       : j['status']       ?? 'pending',
    agentNote    : j['agentNote'],
    createdAt    : j['createdAt']    ?? '',
    userId       : j['userId'],
    user         : j['user'] != null ? UserModel.fromJson(j['user']) : null,
  );

  DateTime get date => DateTime.tryParse(createdAt) ?? DateTime.now();

  String get dateFormatted {
    final d = date;
    return '${d.day.toString().padLeft(2,'0')}/'
           '${d.month.toString().padLeft(2,'0')}/'
           '${d.year}';
  }

  String get locationLabel {
    final parts = <String>[];
    if (block != null && block!.isNotEmpty) parts.add(block!);
    if (floor != null && floor!.isNotEmpty) parts.add(floor!);
    return parts.isNotEmpty ? parts.join(' – ') : '';
  }
}

// ── Modèle Complaint ───────────────────────────────────────────────
class ComplaintModel {
  final int     id;
  final String  title;
  final String  description;
  final String  category;
  final String  status;
  final String? image;
  final String  createdAt;
  final int     userId;
  final UserModel? user;
  final UserModel? assignedTechnician;

  const ComplaintModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.image,
    required this.createdAt,
    required this.userId,
    this.user,
    this.assignedTechnician,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> j) => ComplaintModel(
    id                  : j['id'],
    title               : j['title']       ?? '',
    description         : j['description'] ?? '',
    category            : j['category']    ?? 'autre',
    status              : j['status']      ?? 'pending',
    image               : j['image'],
    createdAt           : j['createdAt']   ?? '',
    userId              : j['userId'],
    user                : j['user'] != null ? UserModel.fromJson(j['user']) : null,
    assignedTechnician  : j['assignedTechnician'] != null
                            ? UserModel.fromJson(j['assignedTechnician']) : null,
  );

  DateTime get date => DateTime.tryParse(createdAt) ?? DateTime.now();

  String get dateFormatted {
    final d = date;
    return '${d.day.toString().padLeft(2,'0')}/'
           '${d.month.toString().padLeft(2,'0')}/'
           '${d.year}';
  }

  String get timeFormatted {
    final d = date;
    return '${d.hour.toString().padLeft(2,'0')}:'
           '${d.minute.toString().padLeft(2,'0')}';
  }
}
