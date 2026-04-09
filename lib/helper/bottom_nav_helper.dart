import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/helper/app_helper.dart';

class AppBottomNav {
  AppBottomNav({
    required this.id, 
    this.icon, // Icon chhod diya taaki purana code toot naaye (optional)
    required this.imagePath, // Naya: Image ka path
    this.name
  });

  int id;
  IconData? icon; 
  String imagePath; // <--- Yahan image path store hoga
  String? name;
}

class AppBottomNavHelper {
  static List<AppBottomNav> getBottomNavList() {
    final List<AppBottomNav> list = [];
    
    // --- YAHAN APNE ASSETS LOGO LAGAYE ---
    
    list.add(AppBottomNav(
      id: AppBottomNavKey.home, 
      imagePath: 'assets/icons/home.png', // <--- Home ka Logo
      name: "Home".tr
    ));
    
    list.add(AppBottomNav(
      id: AppBottomNavKey.market, 
      imagePath: 'assets/icons/markets.png', // <--- Market ka Logo
      name: "Markets".tr
    ));
    
    list.add(AppBottomNav(
      id: AppBottomNavKey.trade, 
      imagePath: 'assets/icons/trade.png', // <--- Trade ka Logo
      name: "Trade".tr
    ));

    if (getSettingsLocal()?.enableFutureTrade == 1) {
      list.add(AppBottomNav(
        id: AppBottomNavKey.future, 
        imagePath: 'assets/icons/future.png', // <--- Futures ka Logo
        name: "Futures".tr
      ));
    }
    
    list.add(AppBottomNav(
      id: AppBottomNavKey.wallet, 
      imagePath: 'assets/icons/assets.png', // <--- Wallet ka Logo
      name: "Assets".tr
    ));

    return list;
  }

  static int getNavIndex(int key) {
    return getBottomNavList().indexWhere((element) => element.id == key);
  }
}