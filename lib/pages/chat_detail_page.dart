import 'package:flutter/material.dart';
// import 'history_page.dart'; // Commented out as history_page.dart is not provided
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'history_page.dart';

// ⚠️ Placeholder function for demonstration. Replace with actual implementation.

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  const ChatDetailPage({super.key, required this.chatId});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  List<Map<String, dynamic>> _messages = []; 
  bool _isLoading = true;
  String? _error; // Added for displaying loading/error state
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChatMessages();
  }

  Future<void> _loadChatMessages() async {
    try {
      // เนื่องจาก getChatMessages ถูกแก้ให้คืน List<Map<String, dynamic>> แล้ว
      // ตรงนี้จึงไม่ต้องมีการแปลงซ้ำซ้อน 
      final data = await getChatMessages(widget.chatId);
      setState(() {
        // Cast result to the desired type for state variable
        _messages = data.cast<Map<String, dynamic>>(); 
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "เกิดข้อผิดพลาดในการโหลดข้อมูล: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Display error message if loading failed
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียดแชท')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายละเอียดแชท',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  // ใน ListView.builder ใน _ChatDetailPageState
                  // ...
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    
                    // ให้แน่ใจว่า msg['textresult'] เป็น Map<String, dynamic> ก่อนส่งเข้า function
                    final Map<String, dynamic> textResult = (msg['textresult'] is Map) 
                      ? (msg['textresult'] as Map).cast<String, dynamic>() 
                      : {};

                    switch (msg['type']) {
                      case 'cardEvidence':
                        return _buildCardMessageEvidence(textResult);
                      case 'cardDiagnosis':
                        return _buildCardMessageDiagnosis(textResult);
                      case 'cardSuggest':
                        return _buildCardMessageSuggest(textResult);
                      case 'cardMedicine':
                        return _buildCardMessageMedicine(textResult);
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                  // ...
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildCardMessageEvidence(Map<String, dynamic> data) {
  final evidences = (data['evidences'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  // แยกตาม choice
  final supporting = evidences.where((e) => e["choice"] == "present").toList();
  final conflicting = evidences.where((e) => e["choice"] == "absent").toList();
  final unconfirmed = evidences.where((e) => e["choice"] == "unknown").toList();

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data["title"] ?? "ข้อมูลอาการ",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Supporting evidence
          if (supporting.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...supporting.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Text("+ ",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(e["common_name"] ?? "-"),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // Conflicting evidence
          if (conflicting.isNotEmpty) ...[
            ...conflicting.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Text("- ",
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(e["common_name"] ?? "-"),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          // Unconfirmed evidence
          if (unconfirmed.isNotEmpty) ...[
            ...unconfirmed.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Text("? ",
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(e["common_name"] ?? "-"),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],

          const Divider(),
          const Text(
            "(นี่คือข้อมูลที่ใช้ในการประเมินอัตโนมัติ)",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCardMessageDiagnosis(Map<String, dynamic> data) {
  final conditions = (data['conditions'] as List?) ?? [];
  final triage = data['triage'];

  // แปล triage เป็นข้อความภาษาไทย
  String triageText = "-";
  Color triageColor = Colors.black87;
  if (triage != null) {
    switch (triage['level']) {
      case "self_care":
        triageText = "ดูแลตนเองที่บ้าน";
        triageColor = Colors.green;
        break;
      case "consultation":
        triageText = "แนะนำให้พบแพทย์";
        triageColor = Colors.orange;
        break;
      case "consultation_24":
        triageText = "แนะนำให้พบแพทย์ภายใน 24 ชั่วโมง";
        triageColor = Colors.deepOrange;
        break;
      case "emergency":
        triageText = "พบแพทย์ฉุกเฉิน";
        triageColor = Colors.red;
        break;
      case "emergency_24":
        triageText = "พบแพทย์ฉุกเฉินภายใน 24 ชั่วโมง";
        triageColor = Colors.redAccent;
        break;
    }
  }

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data["title"] ?? "ผลการวินิจฉัยเบื้องต้น",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blueAccent,
                ),
              ),
              const Icon(Icons.local_hospital, size: 24, color: Colors.blueAccent),
            ],
          ),
          const Divider(height: 24, thickness: 1.2),

          // Conditions list
          if (conditions.isNotEmpty) ...[
            const Text(
              "ภาวะที่เป็นไปได้:",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...conditions.map((c) {
              final prob = (c["probability"] as double?) ?? 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c["name_th"] ?? "-",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      "${(prob * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else
            const Text(
              "ไม่มีข้อมูลภาวะที่เป็นไปได้",
              style: TextStyle(color: Colors.black54),
            ),

          const SizedBox(height: 20),

          // Triage info
          if (triage != null) ...[
            Row(
              children: [
                const Text(
                  "ระดับความรุนแรง: ",
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  triageText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: triageColor,
                  ),
                ),
              ],
            ),
          ],
          const Divider(),
          const Text(
            "(นี่คือข้อมูลที่ได้จาก Infermedica)",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCardMessageSuggest(Map<String, dynamic> data) {
  final triageLevel = data['triage_level'];
  final adviceList = (data['advice_list'] as List?) ?? [];

  // กรณีฉุกเฉิน
  if (triageLevel == "emergency" || triageLevel == "emergency_24" || triageLevel == "consultation_24") {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // เรียกฟังก์ชันหาสถานพยาบาลใกล้ๆ
        findNearbyHospitals();
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data["title"] ?? "คำแนะนำฉุกเฉิน",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.redAccent,
                    ),
                  ),
                  const Icon(Icons.warning_amber_rounded,
                      size: 26, color: Colors.redAccent),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 24, thickness: 1.2),
              const Text(
                "กรุณาไปพบแพทย์ฉุกเฉินทันที\n(กดเพื่อหาสถานพยาบาลใกล้เคียง)",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // กรณีทั่วไป
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data["title_suggest"] ?? "คำแนะนำ",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blueAccent,
                ),
              ),
              const Icon(Icons.info_outline,
                  size: 24, color: Colors.blueAccent),
            ],
          ),
          const Divider(height: 24, thickness: 1.2),

          // Advice list
          if (adviceList.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...adviceList.map((section) {
              final topic = section["topic"] ?? "";
              final contents = List<String>.from(section["content"] ?? []);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (topic.isNotEmpty)
                      Text(
                        topic,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 6),
                    ...contents.map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ",
                                style: TextStyle(color: Colors.black54)),
                            Expanded(
                              child: Text(
                                c,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else
            const Text(
              "ไม่มีคำแนะนำเพิ่มเติม",
              style: TextStyle(color: Colors.black54),
            ),
          const SizedBox(height: 20),
          const Divider(),
          const Text(
            "(นี่คือข้อมูลที่ได้จาก AI)",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCardMessageMedicine(Map<String, dynamic> data) {
  final triageLevel = data['triage_level'];
  final medicines = (data['medicine_list'] as List?) ?? [];

  String getMedicineImage(String name) {
    if (name.contains("พารา")) {
      return "assets/images/ยาพารา.png";
    } else if (name.contains("แก้ไอ")) {
      return "assets/images/ยาแก้ไอ.png";
    } else if (name.contains("ลดกรด")) {
      return "assets/images/ยาลดกรด.png";
    }
    return "assets/images/medicine_placeholder.png";
  }

  // 🔴 กรณีอาการ sensitive
  if (triageLevel == "emergency" ||
      triageLevel == "emergency_24" ||
      triageLevel == "consultation_24") {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // TODO: เรียกฟังก์ชันหาสถานพยาบาลใกล้ๆ เช่น goToNearestHospital();
        findNearbyHospitals();
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "อาการที่มีความอ่อนไหว",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.orange,
                    ),
                  ),
                  Icon(Icons.warning_amber_rounded,
                      size: 26, color: Colors.orange),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 24, thickness: 1.2),
              const Text(
                "อาการของท่านเป็นอาการที่มีความอ่อนไหว\nจึงแนะนำให้ปรึกษาแพทย์ผู้เชี่ยวชาญ\n(กดเพื่อหาสถานพยาบาลใกล้เคียง)",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔵 กรณีทั่วไป (โชว์ข้อมูลยาแนะนำ)
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data["title_medicine"] ?? "ข้อมูลยาแนะนำ",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
              const Icon(Icons.medical_services, size: 24, color: Colors.green),
            ],
          ),
          const Divider(height: 24, thickness: 1.2),

          // Medicines list
          if (medicines.isNotEmpty) ...[
            ...medicines.map((m) {
              final name = m["name"] ?? "ชื่อยาไม่ระบุ";
              final usage = m["usage"] ?? "วิธีใช้ไม่ระบุ";
              final precautions = m["precautions"] ?? "ข้อควรระวังไม่ระบุ";

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // แถวบน (รูป + ชื่อยา)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ครึ่งซ้าย (รูปยา) + คงอัตราส่วน
                        Expanded(
                          flex: 1,
                          child: AspectRatio(
                            aspectRatio: 1, // 1:1 → กว้าง = สูง
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  getMedicineImage(name),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.medication,
                                        size: 40, color: Colors.green);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ครึ่งขวา (ชื่อยา)
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),


                    const SizedBox(height: 10),

                    // แถวล่าง (usage + precautions)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "วิธีใช้: $usage",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "ข้อควรระวัง: $precautions",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("ไม่มีข้อมูลยาแนะนำ",
                  style: TextStyle(color: Colors.black54)),
            ),

          const Divider(),
          const Text(
            "(นี่คือข้อมูลที่ได้จาก AI)",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

// Fixed findNearbyHospitals function
Future<void> findNearbyHospitals() async {
  try {
    // 1) หา location ปัจจุบัน
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    double lat = position.latitude;
    double lon = position.longitude;
    
    debugPrint("Current Location: $lat, $lon");

    // 2) ใช้ Overpass API หาโรงพยาบาลใกล้ ๆ (5 กม. รอบตัวเรา)
    final overpassUrl =
        "https://overpass-api.de/api/interpreter?data=[out:json];"
        "("
        "node[\"amenity\"=\"hospital\"](around:5000,$lat,$lon);"
        "way[\"amenity\"=\"hospital\"](around:5000,$lat,$lon);"
        "relation[\"amenity\"=\"hospital\"](around:5000,$lat,$lon);"
        ");"
        "out center;"; // 'out center;' ensures that way and relation elements have a 'center' object for coordinates

    final response = await http.get(Uri.parse(overpassUrl), headers: {
      "User-Agent": "CREATH+/1.0 (kittipongr65@nu.ac.th)"
    });
    
    debugPrint("Overpass API Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final elements = data["elements"] as List;

      if (elements.isEmpty) {
        // Use a simple alert or toast in a real app
        debugPrint("ไม่พบโรงพยาบาลใกล้เคียง");
        return; // Exit function gracefully
      }

      // เอาโรงพยาบาลแรก (ใกล้ที่สุดใน list ที่ Overpass คืนมา)
      final hospital = elements[0];
      
      // Extract coordinates: 'node' elements have 'lat' and 'lon', 
      // 'way'/'relation' (with 'out center;') have 'center' object with 'lat' and 'lon'.
      final hLat = hospital["lat"] ?? hospital["center"]?["lat"];
      final hLon = hospital["lon"] ?? hospital["center"]?["lon"];
      
      if (hLat == null || hLon == null) {
        debugPrint("ไม่สามารถระบุพิกัดโรงพยาบาลได้");
        return;
      }
      
      debugPrint("Nearest Hospital Coords: $hLat, $hLon");

      // 3) สร้าง URL Google Maps เพื่อนำทางไปยังพิกัดโรงพยาบาล
      // Using 'dir' for directions from current location to hospital
      final mapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$hLat,$hLon&travelmode=driving";
      
      if (!await launchUrl(Uri.parse(mapsUrl), mode: LaunchMode.externalApplication)) {
        debugPrint("Could not launch $mapsUrl");
      }
    } else {
      // Use a simple alert or toast in a real app
      debugPrint("API Error: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error in findNearbyHospitals: $e");
    // In a real app, you'd show a generic error to the user
  }
}