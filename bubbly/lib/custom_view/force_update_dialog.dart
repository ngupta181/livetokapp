import 'package:flutter/material.dart';
import 'package:bubbly/services/version_check_service.dart';
import 'package:get/get.dart';
import 'package:bubbly/utils/const_res.dart';
import 'package:bubbly/utils/colors.dart';

class ForceUpdateDialog extends StatelessWidget {
  const ForceUpdateDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isForceUpdate = VersionCheckService.forceUpdate;
    
    return WillPopScope(
      onWillPop: () async => !isForceUpdate, // Only prevent closing if force update
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.system_update,
                size: 50,
                color: ColorRes.colorPrimary,
              ),
              const SizedBox(height: 20),
              Text(
                'New Update Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                VersionCheckService.updateMessage ?? 
                'A new version of the app is available. Please update to continue using the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () => VersionCheckService.openStore(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorRes.colorPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(double.infinity, 45),
                ),
                child: Text(
                  'Update Now',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isForceUpdate) ...[
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Later',
                    style: TextStyle(
                      fontSize: 16,
                      color: ColorRes.colorPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 