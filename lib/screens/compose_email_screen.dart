import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/smtp_service.dart';
import '../providers/auth_provider.dart';

class ComposeEmail extends StatefulWidget {
  const ComposeEmail({super.key});
  @override
  State<ComposeEmail> createState() => _ComposeEmail();
}

class _ComposeEmail extends State<ComposeEmail> {
  late bool showCc = false;
  late bool showBcc = false;
  late bool isSmallScreen = false;
  late double width;
  late double height;
  String? username;
  late String to = '';
  final Map<String, dynamic> option = {
    'cc': '',
    'bcc': '',
  }; // Use a map for options
  String? selectedValue;
  Map<String, dynamic> alertMessage = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    isSmallScreen = width < 800;
    final authProvider = Provider.of<AuthProvider>(context);
    username = authProvider.email;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (!isSmallScreen)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
                    color: Colors.grey.shade400,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('New mail'),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.open_in_full_rounded),
                              iconSize: 16,
                              selectedIcon: const Icon(
                                Icons.close_fullscreen_rounded,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              iconSize: 16,
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (isSmallScreen)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                showMenu(
                                  context: context,
                                  color: const Color(0xFF232923),
                                  position: const RelativeRect.fromLTRB(
                                    1,
                                    20,
                                    0,
                                    0,
                                  ), // Adjust position as needed
                                  items: [
                                    const PopupMenuItem(
                                      value: 1,
                                      child: Text(
                                        'Attache file',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 2,
                                      child: Text(
                                        'Insert From Drive',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Insert photo',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ).then((value) {
                                  if (value != null) {
                                    debugPrint('Selected: $value');
                                  }
                                });
                              },
                              color: Colors.white70,
                              icon: const Icon(Icons.attachment_rounded),
                            ),
                            IconButton(
                              onPressed: () async {
                                if (to == '' &&
                                    option['cc'] == '' &&
                                    option['bcc'] == '') {
                                  setState(() {
                                    alertMessage['content'] =
                                        'Add at least one recipient.';
                                  });
                                  return;
                                }
                                if (username == null ||
                                    username!.isEmpty ||
                                    authProvider.password == null ||
                                    authProvider.password!.isEmpty) {
                                  setState(() {
                                    alertMessage['content'] =
                                        'Login required to send email.';
                                  });
                                  return;
                                }
                                setState(() {
                                  option['username'] = username;
                                  _isLoading = true;
                                });
                                final status =
                                    await SmtpService(
                                      username: username!,
                                      to: to,
                                      option: option,
                                      password: authProvider.password,
                                    ).sendMail();
                                setState(() {
                                  alertMessage['title'] = status;
                                  _isLoading = false;
                                });
                              },
                              color: Colors.white70,
                              icon: const Icon(Icons.send_rounded),
                            ),
                            IconButton(
                              onPressed: () {
                                showMenu(
                                  context: context,
                                  color: const Color(0xFF232923),
                                  position: const RelativeRect.fromLTRB(
                                    1,
                                    20,
                                    0,
                                    0,
                                  ), // Adjust position as needed
                                  items: [
                                    const PopupMenuItem(
                                      value: 1,
                                      child: Text(
                                        'Schedule Send',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 2,
                                      child: Text(
                                        'Add from Contact',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Confidential mode',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Save draft',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Discard',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Settings',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Text(
                                        'Help and Feedback',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ).then((value) {
                                  if (value != null) {
                                    debugPrint('Selected: $value');
                                  }
                                });
                              },
                              color: Colors.white70,
                              icon: const Icon(Icons.more_vert_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                if (isSmallScreen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade600),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('From'),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            username ?? 'Not logged in',
                            style: const TextStyle(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade600),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('To'),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              to = value;
                              option['to'] = value;
                            });
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      if (!showCc && !showBcc && isSmallScreen)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              showCc = true;
                              showBcc = true;
                            });
                          },
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          color: Colors.grey[700],
                        ),
                      if (!showCc &&
                          !isSmallScreen &&
                          option['cc'].trim() == '')
                        TextButton(
                          onPressed: () {
                            setState(() {
                              showCc = true;
                            });
                          },
                          child: const Text('Cc'),
                        ),
                      if (!showBcc &&
                          !isSmallScreen &&
                          option['bcc'].trim() == '')
                        TextButton(
                          onPressed: () {
                            setState(() {
                              showBcc = true;
                            });
                          },
                          child: const Text('Bcc'),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    AnimatedContainer(
                      height: (showCc || option['cc'] != '') ? 49 : 0,
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade600),
                        ),
                      ),
                      child: Row(
                        children:
                            (showCc || option['cc'] != '')
                                ? [
                                  const Text('CC'),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          option['cc'] = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                                : [],
                      ),
                    ),
                    AnimatedContainer(
                      height: (showBcc || option['bcc'] != '') ? 49 : 0,
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade600),
                        ),
                      ),
                      child: Row(
                        children:
                            (showBcc || option['bcc'] != '')
                                ? [
                                  const Text('Bcc'),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          option['bcc'] = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        border: InputBorder.none, //
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ]
                                : [],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade600),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              option['subject'] = value;
                            });
                          },
                          onTap: () {
                            setState(() {
                              showCc = false;
                              showBcc = false;
                            });
                          },
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: InputBorder.none, //
                            hintText: 'Subject',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          option['body'] = value;
                        });
                      },
                      onTap: () {
                        setState(() {
                          showCc = false;
                          showBcc = false;
                        });
                      },
                      maxLines: 50,
                      decoration: const InputDecoration(
                        border: InputBorder.none, //
                        hintText: 'Compose email',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (alertMessage.isNotEmpty)
              AlertDialog(
                title: Text(
                  alertMessage['title'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                content: Text(
                  alertMessage['content'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                backgroundColor: const Color(0xFF232923),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        alertMessage = {};
                      });
                      // Future.delayed(const Duration(seconds: 3), () {
                      //   Navigator.of(context).pop();
                      // });
                      // Navigator.pop(context);
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
