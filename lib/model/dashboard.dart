class EmployeeStats {
  final int allEmployee;
  final int activeEmployee;
  final int inactiveEmployee;
  final int permanentEmployee;
  final int contractEmployee;
  final int allDiplomaNurses;
  final int needToRetire;
  final int soonRetireEmployee;
  final int allClinicalOfficers;
  final int? ungujaEmployee;
  final int? pembaEmployee;
  final int allSpecialists;
  final int allSuperSpecialists;
  final int allPharmacies;
  final int allLaboratories;
  final int allNurses;
  final int allNursesSpecialist;
  final int allDoctors;
  final int allDiplomaLabolatories;
  final int allDiplomaPharmacies;
  final int allDentists;
  final int allDiplomaDentists;
  final int allAmoOfficers;
  final int allAdoOfficers;
  final int allMedical;
  final int allNonMedical;

  EmployeeStats({
    required this.allEmployee,
    required this.activeEmployee,
    required this.inactiveEmployee,
    required this.permanentEmployee,
    required this.contractEmployee,
    required this.allDiplomaNurses,
    required this.needToRetire,
    required this.soonRetireEmployee,
    required this.allClinicalOfficers,
    this.ungujaEmployee,
    this.pembaEmployee,
    required this.allSpecialists,
    required this.allSuperSpecialists,
    required this.allPharmacies,
    required this.allLaboratories,
    required this.allNurses,
    required this.allNursesSpecialist,
    required this.allDoctors,
    required this.allDiplomaLabolatories,
    required this.allDiplomaPharmacies,
    required this.allDentists,
    required this.allDiplomaDentists,
    required this.allAmoOfficers,
    required this.allAdoOfficers,
    required this.allMedical,
    required this.allNonMedical
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeStats(
      allEmployee: json['all_employee'] ?? 0,
      activeEmployee: json['active_employee'] ?? 0,
      inactiveEmployee: json['inactive_employee'] ?? 0,
      permanentEmployee: json['parmanet_employee'] ?? 0,
      contractEmployee: json['contract_employee'] ?? 0,
      allDiplomaNurses: json['all_diploma_nurses'] ?? 0,
      allNursesSpecialist: json['all_nurses_specialist'] ?? 0,
      needToRetire: json['need_to_retire'] ?? 0,
      soonRetireEmployee: json['soon_retire_employee'] ?? 0,
      allClinicalOfficers: json['all_clinical_officers'] ?? 0,
      ungujaEmployee: json['unguja_employee'] ?? 0,
      pembaEmployee: json['pemba_employee'] ?? 0,
      allSpecialists: json['all_specialists'] ?? 0,
      allSuperSpecialists: json['all_super_specialists'] ?? 0,
      allPharmacies: json['all_pharmacies'] ?? 0,
      allLaboratories: json['all_labolatories'] ?? 0,
      allNurses: json['all_nurses'] ?? 0,
      allDoctors: json['all_doctors'] ?? 0,
      allDiplomaLabolatories: json['all_diploma_labolatories'] ?? 0,
      allDiplomaPharmacies: json['all_diploma_pharmacies'] ?? 0,
      allDentists: json['all_dentists'] ?? 0,
      allDiplomaDentists: json['all_diploma_dentists'] ?? 0,
      allAmoOfficers: json['all_amo_officers'] ?? 0,
      allAdoOfficers: json['all_ado_officers'] ?? 0,
      allMedical: json['all_medical'] ?? 0,
      allNonMedical: json['all_non_medical'] ?? 0
    );
  }
}
