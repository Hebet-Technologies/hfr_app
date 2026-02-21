import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:staffportal/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:search_choices/search_choices.dart';
import '../view_model/user_view_model.dart';
import '../widget/button_widget.dart';
import '../widget/dashboard_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {

  late UserViewModel userViewModel;
  @override
  void initState() {
    userViewModel = Provider.of<UserViewModel>(context, listen: false);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      userViewModel.getDashboard(context);
      userViewModel.getStations(context);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: SizedBox(
            height: 68,
            width: MediaQuery.of(context).size.width,
            child: Consumer<UserViewModel>(
              builder: (context, station, child) {
                return SearchChoices.single(
                  items: station.stations.map((station) {
                    return DropdownMenuItem<String>(
                      value: station.workingStationName, // The value is the ID
                      child: Text(
                        station.workingStationName, // Display the name
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  value: station.selectedStationId, // Keep selected value as ID
                  hint: station.selectedStationName ?? "Select Working Station",
                  searchHint: "Search Working Station",
                  onChanged: (newValue) {
                    final selectedStation = station.stations.firstWhere(
                          (station) => station.workingStationName == newValue,
                    );
                    station.setSelectedStation(selectedStation.workingStationId.toString(), newValue);
                    station.getSelectedDashboard(context, selectedStation.workingStationId);
                  },
                  isExpanded: true,
                  style: const TextStyle(fontSize: 14),
                  displayClearIcon: false,
                  underline: Container(),
                  searchInputDecoration: InputDecoration(
                    hintText: 'Search Working Station',
                    hintStyle: const TextStyle(fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  menuBackgroundColor: Colors.white,
                  dialogBox: true,
                  closeButton: "Close",
                  searchFn: null, // Remove custom searchFn
                );
              }),
        )
      ),
      body: Consumer<UserViewModel>(builder: (context, dash, child){
        return  Container(
          color: Colors.black12,
          padding: const EdgeInsets.all(8),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: dash.isDashboardLoading
          ? const Center(child: CircularProgressIndicator(),)
          : dash.msgDashboard == "error"
          ? Center(child: SizedBox(
            height: 100,
            child: Column(
              children: [
                const Text("No Internet Connection"),
                const SizedBox(height: 10,),
                SizedBox(
                  width: 100,
                  child: ButtonWidget(
                      title: "Retry",
                      color: blueAccent,
                      textColor: white,
                      onPressed: ()=> userViewModel.getDashboard(context)
                  ),
                )
              ],
            ),
          )): RefreshIndicator(
        onRefresh:()=> dash.getDashboard(context),
        child: SingleChildScrollView(
            child: Column(
              children: [
                const Text("EMPLOYEE DASHBOARD", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      children: [
                        DashboardCard(
                          count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allEmployee : 0,
                          title: 'All',
                          onPressed: () {  },
                        ),
                        if(dash.selectedStationId == null)
                        DashboardCard(
                          count: dash.dashboard.isNotEmpty ? dash.dashboard.first.ungujaEmployee! : 0,
                          title: 'Unguja',
                          onPressed: () {  },
                        ),
                        if(dash.selectedStationId == null)
                        DashboardCard(
                          count: dash.dashboard.isNotEmpty ? dash.dashboard.first.pembaEmployee! : 0,
                          title: 'Pemba',
                          onPressed: () {  },
                        ),
                        if(dash.selectedStationId == null)
                        DashboardCard(
                          count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allMedical! : 0,
                          title: 'Medical',
                          onPressed: () {  },
                        ),
                        if(dash.selectedStationId == null)
                          DashboardCard(
                            count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allNonMedical! : 0,
                            title: 'Non Medical',
                            onPressed: () {  },
                          ),
                        DashboardCard(
                          count: dash.dashboard.isNotEmpty ? dash.dashboard.first.activeEmployee : 0,
                          title: 'Active',
                          onPressed: () {  },
                        ),
                        DashboardCard(
                          count: dash.dashboard.isNotEmpty ? dash.dashboard.first.inactiveEmployee : 0,
                          title: 'Inactive',
                          onPressed: () {  },
                        ),
                        DashboardCard(
                          count: dash.dashboard.isNotEmpty ? dash.dashboard.first.permanentEmployee : 0,
                          title: 'Permanent',
                          onPressed: () {  },
                        ),
                        DashboardCard(
                          count: dash.dashboard.isNotEmpty ? dash.dashboard.first.contractEmployee : 0,
                          title: 'Contract',
                          onPressed: () {  },
                        ),
                        DashboardCard(
                          count: dash.dashboard.isNotEmpty ? dash.dashboard.first.soonRetireEmployee : 0,
                          title: 'Nearly To\nRetire',
                          onPressed: () {  },
                        ),
                        DashboardCard(
                          count: dash.dashboard.isNotEmpty ? dash.dashboard.first.needToRetire : 0,
                          title: 'Need To\nRetire',
                          onPressed: () {  },
                        ),
                      ]
                  ),
                const SizedBox(height: 10,),
                const Text("EMPLOYEE BY CADRE", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    children: [
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allSuperSpecialists : 0,
                        title: 'Super\nSpecialists',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allSpecialists : 0,
                        title: 'Specialists',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allDoctors : 0,
                        title: 'Medical\nDoctors',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allAmoOfficers : 0,
                        title: 'AMO',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allClinicalOfficers : 0,
                        title: 'Clinical\nOfficers',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allDentists : 0,
                        title: 'Medical\nDentist',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allAdoOfficers : 0,
                        title: 'ADO',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allDiplomaDentists : 0,
                        title: 'Clinical\nDentist',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allNursesSpecialist : 0,
                        title: 'Nurses\nSpecialists',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allNurses : 0,
                        title: 'Degree\nNurses',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allDiplomaNurses : 0,
                        title: 'Diploma\nNurses',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allPharmacies : 0,
                        title: 'Pharmacists',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allDiplomaPharmacies : 0,
                        title: 'Pharmacy\nTechnicians',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allLaboratories : 0,
                        title: 'Lab\nScientists',
                        onPressed: () {  },
                      ),
                      DashboardCard(
                        count: dash.dashboard.isNotEmpty ? dash.dashboard.first.allDiplomaLabolatories : 0,
                        title: 'Lab\nTechnicians',
                        onPressed: () {  },
                      ),
                    ]
                )
              ],
            ),
          ))
        );
      })
    );
  }
}
