import 'package:flutter/material.dart';

// class NavbarBottom extends StatefulWidget{
//   const NavbarBottom({super.key});

//   @override
//   State<NavbarBottom> createState() => _NavbarBottomState();
// }

// class _NavbarBottomState extends State<NavbarBottom> {
//   int currentIndex = 0;

//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: currentIndex,
//       onTap: (index) {
//         setState(() {
//           currentIndex = index;
//         });
//       },
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home),
//           label: 'Home',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.chat),
//           label: 'Chat',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.person),
//           label: 'Profile',
//         ),
//       ],
//     );
//   }
// }
class CustomNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton; // เพิ่ม option สำหรับแสดงปุ่มย้อนกลับ
  final List<Widget>? actions; // เพิ่ม option สำหรับ actions (ปุ่มทางขวา)

  const CustomNavbar({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: showBackButton ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop(); // ย้อนกลับไปหน้าก่อนหน้า
        },
      ) : null,
      actions: actions,
      // คุณสามารถเพิ่มคุณสมบัติอื่นๆ ของ AppBar ได้ที่นี่ เช่น backgroundColor, elevation
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // กำหนดความสูงมาตรฐานของ AppBar
}