import 'package:flutter/material.dart';

class TaskScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              _buildHeader(),
              const SizedBox(height: 30),
              
              
              IntrinsicHeight(
                child: Row(
                  children: [
                    _buildTimelineConnector(), 
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          taskCard(
                              "Prendre les médicaments",
                              Colors.indigo,
                              ["08:00 Médicaments du matin", "09:00 Vérifier alarme", "09:15 Noter la prise"],
                              "assets/medicine.png",
                              statusColor: Colors.green), 
                          
                          const SizedBox(height: 15),
                          
                          taskCard(
                              "Repas équilibré",
                              Colors.orange,
                              ["08:30 Petit-déjeuner", "13:00 Déjeuner", "15:00 Boire eau"],
                              "assets/food.png",
                              statusColor: Colors.orange), 
                          
                          const SizedBox(height: 15),

                          taskCard(
                              "Activité physique légère",
                              Colors.green,
                              ["10:00 Marche", "10:30 Exercices", "10:45 Étirement"],
                              "assets/sport.png",
                              statusColor: Colors.red),

                          
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 
  Widget taskCard(String title, Color color, List<String> subTasks, String assetPath, {required Color statusColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              Image.asset(assetPath, width: 30, height: 30, errorBuilder: (c, e, s) => Icon(Icons.bolt, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ...subTasks.map((task) => Text(task, style: TextStyle(color: Colors.grey[700], fontSize: 13))).toList(),
        ],
      ),
    );
  }

  
  Widget _buildTimelineConnector() {
    return Column(
      children: [
        _dot(Colors.green), 
        Expanded(child: Container(width: 2, color: Colors.pink.shade100)),
        _dot(Colors.orange), 
        Expanded(child: Container(width: 2, color: Colors.pink.shade100)),
        _dot(Colors.red), 
        
      ],
    );
  }

  Widget _dot(Color color) {
    return Container(
      height: 14,
      width: 14,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
    );
  }
  
  Widget _buildHeader() {
     
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         const Icon(Icons.arrow_back_ios, size: 20),
         ElevatedButton.icon(
           onPressed: () {},
           icon: const Icon(Icons.add),
           label: const Text("Add Task"),
           style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 142, 157, 245), shape: const StadiumBorder()),
         )
       ],
     );
  }
}