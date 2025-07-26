import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'form_builder_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_builder_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<DocumentSnapshot> _userForms = [];
  bool _isLoadingForms = false;
  List<DocumentSnapshot> _trashedForms = [];
  bool _isLoadingTrashedForms = false;
  List<DocumentSnapshot> _userQuizzes = [];
  bool _isLoadingQuizzes = false;

  @override
  void initState() {
    super.initState();
    _loadUserForms();
    _loadTrashedForms();
    _loadUserQuizzes();
  }

  Future<void> _loadUserForms() async {
    setState(() => _isLoadingForms = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('forms')
            .where('createdBy', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .orderBy('updatedAt', descending: true)
            .get();
        
        setState(() {
          _userForms = querySnapshot.docs;
        });
      }
    } catch (e) {
      print('Error loading forms: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading forms: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingForms = false);
    }
  }

  Future<void> _loadTrashedForms() async {
    setState(() => _isLoadingTrashedForms = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('forms')
            .where('createdBy', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: true)
            .orderBy('deletedAt', descending: true)
            .get();
        
        setState(() {
          _trashedForms = querySnapshot.docs;
        });
      }
    } catch (e) {
      print('Error loading trashed forms: $e');
    } finally {
      setState(() => _isLoadingTrashedForms = false);
    }
  }

  Future<void> _loadUserQuizzes() async {
    setState(() => _isLoadingQuizzes = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('forms')
            .where('createdBy', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .where('isQuiz', isEqualTo: true)
            .orderBy('updatedAt', descending: true)
            .get();
        
        setState(() {
          _userQuizzes = querySnapshot.docs;
        });
      }
    } catch (e) {
      print('Error loading quizzes: $e');
    } finally {
      setState(() => _isLoadingQuizzes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Prem's Form",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A73E8),
        elevation: 1,
        automaticallyImplyLeading: !isDesktop,
        leading: !isDesktop
            ? IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        actions: [
          if (!isDesktop)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _showCreateDialog(),
            ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Color(0xFF1A73E8),
              radius: isDesktop ? 16 : 14,
              child: Text(
                FirebaseAuth.instance.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 14 : 12,
                ),
              ),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                bool? shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1A73E8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Logout', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                
                if (shouldLogout == true) {
                  await FirebaseAuth.instance.signOut();
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.grey[700]),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: Colors.grey[700]),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red[600]),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red[600])),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: isDesktop ? 16 : 8),
        ],
      ),
      drawer: !isDesktop ? _buildMobileDrawer() : null,
      bottomNavigationBar: !isDesktop ? _buildBottomNavBar() : null,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 280,
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(),
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text('Create', style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A73E8),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 2,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildNavItem(Icons.description_outlined, 'Recent forms', 0),
                    _buildNavItem(Icons.folder_outlined, 'My forms', 1),
                    _buildNavItem(Icons.quiz_outlined, 'My quizzes', 2),
                    _buildNavItem(Icons.star_outline, 'Starred', 3),
                    _buildNavItem(Icons.delete_outline, 'Trash', 4),
                    SizedBox(height: 20),
                    Divider(),
                    _buildNavItem(Icons.analytics_outlined, 'Analytics', 5),
                    _buildNavItem(Icons.settings_outlined, 'Settings', 6),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: Colors.grey[300]),
        Expanded(
          child: _buildMainContent(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _buildMainContent();
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF1A73E8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text(
                    FirebaseAuth.instance.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'A',
                    style: TextStyle(
                      color: Color(0xFF1A73E8),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? 'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showCreateDialog();
              },
              icon: Icon(Icons.add, color: Colors.white),
              label: Text('Create', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A73E8),
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 2,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMobileNavItem(Icons.description_outlined, 'Recent forms', 0),
                _buildMobileNavItem(Icons.folder_outlined, 'My forms', 1),
                _buildMobileNavItem(Icons.quiz_outlined, 'My quizzes', 2),
                _buildMobileNavItem(Icons.star_outline, 'Starred', 3),
                _buildMobileNavItem(Icons.delete_outline, 'Trash', 4),
                Divider(),
                _buildMobileNavItem(Icons.analytics_outlined, 'Analytics', 5),
                _buildMobileNavItem(Icons.settings_outlined, 'Settings', 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Color(0xFF1A73E8),
      unselectedItemColor: Colors.grey[600],
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          label: 'Recent',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_outlined),
          label: 'My Forms',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz_outlined),
          label: 'Quizzes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star_outline),
          label: 'Starred',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }

  Widget _buildMobileNavItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Color(0xFF1A73E8) : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Color(0xFF1A73E8) : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Color(0xFF1A73E8).withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Color(0xFF1A73E8) : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Color(0xFF1A73E8) : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Color(0xFF1A73E8).withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildMainContent() {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    switch (_selectedIndex) {
      case 0:
        return _buildRecentForms(isDesktop);
      case 1:
        return _buildMyForms(isDesktop);
      case 2:
        return _buildMyQuizzes(isDesktop);
      case 3:
        return _buildStarred(isDesktop);
      case 4:
        return _buildTrash(isDesktop);
      case 5:
        return _buildAnalytics(isDesktop);
      case 6:
        return _buildSettings(isDesktop);
      default:
        return _buildRecentForms(isDesktop);
    }
  }

  Widget _buildRecentForms(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent forms',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (isDesktop)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _loadUserForms,
                      tooltip: 'Refresh',
                    ),
                    IconButton(
                      icon: Icon(Icons.view_module_outlined),
                      onPressed: () {},
                      tooltip: 'Grid view',
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Start a new form',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          isDesktop
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTemplateCard('Blank form', Icons.description_outlined, true, isDesktop),
                      _buildTemplateCard('Contact information', Icons.contact_page_outlined, false, isDesktop),
                      _buildTemplateCard('Registration form', Icons.app_registration_outlined, false, isDesktop),
                      _buildTemplateCard('Feedback form', Icons.feedback_outlined, false, isDesktop),
                      _buildTemplateCard('Quiz template', Icons.quiz_outlined, false, isDesktop),
                    ],
                  ),
                )
              : GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                  children: [
                    _buildTemplateCard('Blank form', Icons.description_outlined, true, isDesktop),
                    _buildTemplateCard('Contact info', Icons.contact_page_outlined, false, isDesktop),
                    _buildTemplateCard('Registration', Icons.app_registration_outlined, false, isDesktop),
                    _buildTemplateCard('Feedback', Icons.feedback_outlined, false, isDesktop),
                  ],
                ),
          SizedBox(height: isDesktop ? 32 : 24),
          Row(
            children: [
              Text(
                'Recent forms',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Spacer(),
              if (!isDesktop)
                IconButton(
                  icon: Icon(Icons.refresh, size: 20),
                  onPressed: _loadUserForms,
                ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: _isLoadingForms
                ? Center(child: CircularProgressIndicator())
                : _userForms.isEmpty
                    ? _buildEmptyState(isDesktop)
                    : _buildFormsList(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: isDesktop ? 80 : 60,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No forms yet',
            style: TextStyle(
              fontSize: isDesktop ? 20 : 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first form to get started',
            style: TextStyle(
              fontSize: isDesktop ? 14 : 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(),
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Create form', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1A73E8),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 20,
                vertical: isDesktop ? 12 : 10,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormsList(bool isDesktop) {
    return ListView.builder(
      itemCount: _userForms.length,
      itemBuilder: (context, index) {
        final form = _userForms[index];
        final formData = form.data() as Map<String, dynamic>;
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FormBuilderScreen(formId: form.id),
                ),
              ).then((_) => _loadUserForms());
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: formData['isQuiz'] == true 
                          ? Color(0xFF34A853).withOpacity(0.1)
                          : Color(0xFF1A73E8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      formData['isQuiz'] == true ? Icons.quiz_outlined : Icons.description_outlined,
                      color: formData['isQuiz'] == true ? Color(0xFF34A853) : Color(0xFF1A73E8),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formData['title'] ?? 'Untitled Form',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          formData['description'] ?? 'No description',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: formData['isPublished'] == true 
                                    ? Colors.green[50] 
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                formData['isPublished'] == true ? 'Published' : 'Draft',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: formData['isPublished'] == true 
                                      ? Colors.green[700] 
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '${(formData['questions'] as List?)?.length ?? 0} questions',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (formData['isQuiz'] == true) ...[
                              SizedBox(width: 12),
                              Text(
                                '${formData['settings']?['totalPoints'] ?? 0} pts',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF34A853),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 16),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        value: 'edit',
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(Icons.copy, size: 16),
                          title: Text('Duplicate'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        value: 'duplicate',
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(Icons.delete, size: 16, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                        value: 'delete',
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FormBuilderScreen(formId: form.id),
                            ),
                          ).then((_) => _loadUserForms());
                          break;
                        case 'duplicate':
                          _duplicateForm(form.id);
                          break;
                        case 'delete':
                          _deleteForm(form.id);
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _duplicateForm(String formId) async {
    try {
      final formDoc = await FirebaseFirestore.instance
          .collection('forms')
          .doc(formId)
          .get();
      
      if (formDoc.exists) {
        final formData = formDoc.data()!;
        formData['title'] = '${formData['title']} (Copy)';
        formData['isPublished'] = false;
        formData['createdAt'] = DateTime.now().toIso8601String();
        formData['updatedAt'] = DateTime.now().toIso8601String();
        
        await FirebaseFirestore.instance
            .collection('forms')
            .add(formData);
        
        _loadUserForms();
        _loadUserQuizzes();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form duplicated successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error duplicating form: $e')),
      );
    }
  }

  Future<void> _deleteForm(String formId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move to Trash'),
        content: Text('Are you sure you want to move this form to trash?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text('Move to Trash'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('forms')
            .doc(formId)
            .update({
          'isDeleted': true,
          'deletedAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
        
        _loadUserForms();
        _loadUserQuizzes();
        _loadTrashedForms();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Form moved to trash successfully!'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _restoreForm(formId),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving form to trash: $e')),
        );
      }
    }
  }

  Future<void> _restoreForm(String formId) async {
    try {
      await FirebaseFirestore.instance
          .collection('forms')
          .doc(formId)
          .update({
        'isDeleted': false,
        'deletedAt': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      _loadUserForms();
      _loadUserQuizzes();
      _loadTrashedForms();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Form restored successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring form: $e')),
      );
    }
  }

  Future<void> _permanentlyDeleteForm(String formId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete'),
        content: Text('Are you sure you want to permanently delete this form? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete Forever'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('forms')
            .doc(formId)
            .delete();
        
        _loadTrashedForms();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form permanently deleted!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting form: $e')),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildTemplateCard(String title, IconData icon, bool isBlank, bool isDesktop) {
    return Container(
      margin: EdgeInsets.only(right: isDesktop ? 16 : 0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FormBuilderScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: isDesktop ? 160 : null,
          height: isDesktop ? 200 : null,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBlank ? Color(0xFF1A73E8) : Colors.grey[300]!,
              width: isBlank ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isBlank ? Color(0xFF1A73E8).withOpacity(0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: isDesktop ? 48 : 36,
                      color: isBlank ? Color(0xFF1A73E8) : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyForms(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Forms',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadUserForms,
                tooltip: 'Refresh',
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: _isLoadingForms
                ? Center(child: CircularProgressIndicator())
                : _userForms.isEmpty
                    ? _buildEmptyState(isDesktop)
                    : _buildFormsList(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildMyQuizzes(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Quizzes',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadUserQuizzes,
                tooltip: 'Refresh',
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: _isLoadingQuizzes
                ? Center(child: CircularProgressIndicator())
                : _userQuizzes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_outlined, size: isDesktop ? 80 : 60, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No quizzes yet',
                              style: TextStyle(
                                fontSize: isDesktop ? 20 : 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create your first quiz to get started',
                              style: TextStyle(
                                fontSize: isDesktop ? 14 : 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _showCreateDialog(),
                              icon: Icon(Icons.add, color: Colors.white),
                              label: Text('Create quiz', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF34A853),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 24 : 20,
                                  vertical: isDesktop ? 12 : 10,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildQuizzesList(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesList(bool isDesktop) {
    return ListView.builder(
      itemCount: _userQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = _userQuizzes[index];
        final quizData = quiz.data() as Map<String, dynamic>;
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FormBuilderScreen(formId: quiz.id),
                ),
              ).then((_) => _loadUserQuizzes());
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF34A853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.quiz_outlined,
                      color: Color(0xFF34A853),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quizData['title'] ?? 'Untitled Quiz',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          quizData['description'] ?? 'No description',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: quizData['isPublished'] == true 
                                    ? Colors.green[50] 
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                quizData['isPublished'] == true ? 'Published' : 'Draft',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: quizData['isPublished'] == true 
                                      ? Colors.green[700] 
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '${(quizData['questions'] as List?)?.length ?? 0} questions',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '${quizData['settings']?['totalPoints'] ?? 0} pts',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF34A853),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 16),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        value: 'edit',
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(Icons.copy, size: 16),
                          title: Text('Duplicate'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        value: 'duplicate',
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(Icons.delete, size: 16, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                        value: 'delete',
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FormBuilderScreen(formId: quiz.id),
                            ),
                          ).then((_) => _loadUserQuizzes());
                          break;
                        case 'duplicate':
                          _duplicateForm(quiz.id);
                          break;
                        case 'delete':
                          _deleteForm(quiz.id);
                          break;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStarred(bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, size: isDesktop ? 80 : 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Starred',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Your starred forms will appear here',
            style: TextStyle(fontSize: isDesktop ? 14 : 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTrash(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Trash',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadTrashedForms,
                tooltip: 'Refresh',
              ),
              if (_trashedForms.isNotEmpty)
                TextButton.icon(
                  onPressed: _emptyTrash,
                  icon: Icon(Icons.delete_forever, color: Colors.red),
                  label: Text('Empty Trash', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: _isLoadingTrashedForms
                ? Center(child: CircularProgressIndicator())
                : _trashedForms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: isDesktop ? 80 : 60,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Trash is empty',
                              style: TextStyle(
                                fontSize: isDesktop ? 20 : 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Deleted forms will appear here',
                              style: TextStyle(
                                fontSize: isDesktop ? 14 : 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildTrashedFormsList(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashedFormsList(bool isDesktop) {
    return ListView.builder(
      itemCount: _trashedForms.length,
      itemBuilder: (context, index) {
        final form = _trashedForms[index];
        final formData = form.data() as Map<String, dynamic>;
        final deletedAt = DateTime.parse(formData['deletedAt']);
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red[600],
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formData['title'] ?? 'Untitled Form',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Deleted ${_getTimeAgo(deletedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${(formData['questions'] as List?)?.length ?? 0} questions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.restore, color: Colors.green[600]),
                      onPressed: () => _restoreForm(form.id),
                      tooltip: 'Restore',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_forever, color: Colors.red[600]),
                      onPressed: () => _permanentlyDeleteForm(form.id),
                      tooltip: 'Delete Forever',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _emptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Empty Trash'),
        content: Text('Are you sure you want to permanently delete all forms in trash? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Empty Trash'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (final form in _trashedForms) {
          batch.delete(form.reference);
        }
        await batch.commit();
        
        _loadTrashedForms();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trash emptied successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error emptying trash: $e')),
        );
      }
    }
  }

  Widget _buildAnalytics(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 24),
          isDesktop
              ? Row(
                  children: [
                    Expanded(child: _buildAnalyticsCard('Total Forms', '${_userForms.length}', Icons.description, Color(0xFF1A73E8))),
                    SizedBox(width: 16),
                    Expanded(child: _buildAnalyticsCard('Total Quizzes', '${_userQuizzes.length}', Icons.quiz, Color(0xFF34A853))),
                    SizedBox(width: 16),
                    Expanded(child: _buildAnalyticsCard('Active Forms', '${_userForms.where((f) => (f.data() as Map)['isPublished'] == true).length}', Icons.trending_up, Color(0xFFFF9800))),
                  ],
                )
              : Column(
                  children: [
                    _buildAnalyticsCard('Total Forms', '${_userForms.length}', Icons.description, Color(0xFF1A73E8)),
                    SizedBox(height: 12),
                    _buildAnalyticsCard('Total Quizzes', '${_userQuizzes.length}', Icons.quiz, Color(0xFF34A853)),
                    SizedBox(height: 12),
                    _buildAnalyticsCard('Active Forms', '${_userForms.where((f) => (f.data() as Map)['isPublished'] == true).length}', Icons.trending_up, Color(0xFFFF9800)),
                  ],
                ),
          SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: isDesktop ? 80 : 60, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    _userForms.isEmpty && _userQuizzes.isEmpty ? 'No data available' : 'Analytics Dashboard',
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _userForms.isEmpty && _userQuizzes.isEmpty ? 'Create forms to see analytics' : 'Detailed analytics coming soon',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 24),
          _buildSettingsCard(
            'Account',
            'Manage your account settings',
            Icons.person_outline,
            () {},
          ),
          _buildSettingsCard(
            'Notifications',
            'Configure notification preferences',
            Icons.notifications_outlined,
            () {},
          ),
          _buildSettingsCard(
            'Privacy',
            'Privacy and data settings',
            Icons.privacy_tip_outlined,
            () {},
          ),
          _buildSettingsCard(
            'About',
            'App information and support',
            Icons.info_outline,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Color(0xFF1A73E8), size: 24),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }




// Update your _showCreateDialog method
void _showCreateDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Create new'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.description_outlined, color: Color(0xFF1A73E8)),
              title: Text('Form'),
              subtitle: Text('Create a new form'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FormBuilderScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.quiz_outlined, color: Color(0xFF34A853)),
              title: Text('Quiz'),
              subtitle: Text('Create a new quiz'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuizBuilderScreen(), // Now uses QuizBuilderScreen
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
}