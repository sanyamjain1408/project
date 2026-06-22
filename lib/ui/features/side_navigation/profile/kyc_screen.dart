import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tradexpro_flutter/data/local/constants.dart';
import 'package:tradexpro_flutter/data/models/kyc_details.dart';
import 'package:tradexpro_flutter/utils/alert_util.dart';
import 'package:tradexpro_flutter/utils/button_util.dart';
import 'package:tradexpro_flutter/utils/image_util.dart';
import 'package:tradexpro_flutter/utils/persona_util.dart';
import 'package:tradexpro_flutter/utils/text_util.dart';
import 'package:tradexpro_flutter/utils/common_utils.dart';
import 'package:tradexpro_flutter/utils/dimens.dart';
import 'package:tradexpro_flutter/utils/spacers.dart';
import '../../../../helper/app_checker.dart';
import 'my_profile_controller.dart';
import 'package:tradexpro_flutter/data/models/kyc_details.dart';
import 'package:dotted_border/dotted_border.dart';

const _dmSans = 'DMSans';

const _bg = Color(0xFF121212);
const _cardBg = Color(0xFF1E1E1E);
const _green = Color(0xFFCCFF00);
const _white = Color(0xFFFFFFFF);
const _grey = Color(0xFF8A8A8A);
const _divider = Color(0xFF2A2A2A);

const Color _primary = Color(0xFF111111);
const Color _secondary = Color(0xFF1A1A1A);
const Color _textSecondary = Color(0xFFCCFF00);

// ─── MAIN KYC SCREEN (kept for _wrapScreen compatibility) ────────────────────
class KYCScreen extends StatefulWidget {
  const KYCScreen({super.key});

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  final _controller = Get.put(MyProfileController());
  Rx<KycDetails> kycDetailsRx = KycDetails().obs;
  Rx<KycSettings> kycSettingsRx = KycSettings(enabledKycType: 0).obs;
  RxBool isDataLoading = true.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getKYCSettingsDetails((settings) {
        isDataLoading.value = false;
        kycSettingsRx.value = settings;
        final kycDetails = settings.enabledKycUserDetails;
        if (kycDetails != null && kycDetails is KycDetails) {
          kycDetailsRx.value = kycDetails;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isDataLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _green));
      }
      final settings = kycSettingsRx.value;
      if (settings.enabledKycType == 1) {
        return _ManualKycListView(
          details: kycDetailsRx.value,
          controller: _controller,
          onUpdated: (d) => kycDetailsRx.value = d,
        );
      } else if (settings.enabledKycType == 2) {
        if (settings.enabledKycUserDetails?.persona?.isVerified == 1) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.how_to_reg, color: _green, size: 60),
                SizedBox(height: 12),
                Text(
                  "KYC Verified Successfully",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: _dmSans,
                  ),
                ),
              ],
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera_outlined, color: _green, size: 60),
              const SizedBox(height: 12),
              const Text(
                "Verify your identity",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: _dmSans,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                ),
                onPressed: () => _startPersonaVerification(),
                child: const Text(
                  "Start",
                  style: TextStyle(
                    fontFamily: _dmSans,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_disabled, color: Colors.white54, size: 60),
            SizedBox(height: 12),
            Text(
              "KYC Disabled",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: _dmSans,
              ),
            ),
          ],
        ),
      );
    });
  }

  void _startPersonaVerification() {
    PersonaUtil().start(
      Theme.of(context),
      gUserRx.value,
      kycSettingsRx.value.personaCredentialsDetails,
      (success, inquiryId) {
        if (success) {
          _controller.verifyThirdPartyKyc(inquiryId, (onSuccess) {
            _controller.getKYCSettingsDetails(
              (settings) => kycSettingsRx.value = settings,
            );
          });
        }
      },
    );
  }
}

// ─── MANUAL KYC LIST ─────────────────────────────────────────────────────────
class _ManualKycListView extends StatefulWidget {
  final KycDetails details;
  final MyProfileController controller;
  final ValueChanged<KycDetails> onUpdated;

  const _ManualKycListView({
    required this.details,
    required this.controller,
    required this.onUpdated,
  });

  @override
  State<_ManualKycListView> createState() => _ManualKycListViewState();
}

class _ManualKycListViewState extends State<_ManualKycListView> {
  File? _selfieFile;
  bool _isSelfieUploading = false;
  bool _isSelfieUploadedSuccessfully = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        if (widget.details.nid != null)
          _kycListTile(
            context,
            icon: Icons.credit_card_outlined,
            title: "Upload your ID Card",
            status: widget.details.nid?.status,
            onTap: () => _goToUpload(
              context,
              title: "ID Card",
              kyc: widget.details.nid,
              type: IdVerificationType.nid,
            ),
          ),
        if (widget.details.passport != null)
          _kycListTile(
            context,
            icon: Icons.book_outlined,
            title: "Upload your Passport",
            status: widget.details.passport?.status,
            onTap: () => _goToUpload(
              context,
              title: "Passport",
              kyc: widget.details.passport,
              type: IdVerificationType.passport,
            ),
          ),
        if (widget.details.driving != null)
          _kycListTile(
            context,
            icon: Icons.drive_eta_outlined,
            title: "Upload your Driving License",
            status: widget.details.driving?.status,
            onTap: () => _goToUpload(
              context,
              title: "Driving License",
              kyc: widget.details.driving,
              type: IdVerificationType.driving,
            ),
          ),
        if (widget.details.voter != null)
          _kycListTile(
            context,
            icon: Icons.how_to_vote_outlined,
            title: "Upload your Voter Card",
            status: widget.details.voter?.status,
            onTap: () => _goToUpload(
              context,
              title: "Voter Card",
              kyc: widget.details.voter,
              type: IdVerificationType.voter,
            ),
          ),
        _selfieInlineTile(context),
        const SizedBox(height: 30),
        _submitButton(),
      ],
    );
  }

  void _goToUpload(
    BuildContext context, {
    required String title,
    KycObject? kyc,
    required IdVerificationType type,
  }) {
    // Check if document is already approved or pending
    if (kyc?.status != null && kyc!.status!.isNotEmpty) {
      showToast("Document already uploaded with status: ${kyc.status}", isError: false);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KycUploadPage(
          title: title,
          kyc: kyc,
          type: type,
          controller: widget.controller,
          onUploaded: widget.onUpdated,
        ),
      ),
    );
  }

  Widget _kycListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? status,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: _dmSans,
                        ),
                      ),
                      if (status != null && status.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "✓ Uploaded",
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: _dmSans,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: _green, size: 16),
              ],
            ),
            if (status != null && status.isNotEmpty)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: _dmSans,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == "approved" || status == "1") {
      return const Color(0xFF73FFAA); // Green
    } else if (status.toLowerCase() == "pending" || status == "0") {
      return const Color(0xFFF7D774); // Yellow
    } else {
      return const Color(0xFFFF8F8F); // Red (Rejected)
    }
  }

  Color _getStatusBackgroundColor(String status) {
    if (status.toLowerCase() == "approved" || status == "1") {
      return const Color(0xFF153021); // Dark Green
    } else if (status.toLowerCase() == "pending" || status == "0") {
      return const Color(0xFF302912); // Dark Yellow
    } else {
      return const Color(0xFF301616); // Dark Red
    }
  }

  Widget _selfieInlineTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickSelfie(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.face_outlined, color: Colors.white, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Upload your Selfie",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: _dmSans,
                        ),
                      ),
                      if (_selfieFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _isSelfieUploadedSuccessfully ? "✓ Selfie submitted" : "✓ Selfie selected",
                            style: const TextStyle(
                              color: _green,
                              fontSize: 12,
                              fontFamily: _dmSans,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _selfieFile != null ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: _green,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_selfieFile == null)
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _green.withOpacity(0.5)),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 32),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_selfieFile!, height: 100, fit: BoxFit.cover),
              ),
          ],
        ),
      ),
    );
  }

  void _pickSelfie(BuildContext context) {
    showImageChooser(
      context,
      (chooseFile, isGallery) {
        if (isGallery) {
          setState(() {
            _selfieFile = chooseFile;
            _isSelfieUploadedSuccessfully = false; // Re-enable submit button
          });
        } else {
          saveFileOnTempPath(
            chooseFile,
            onNewFile: (f) => setState(() {
              _selfieFile = f;
              _isSelfieUploadedSuccessfully = false; // Re-enable submit button
            }),
          );
        }
      },
      isCrop: false,
      isGallery: true,
    );
  }

  Widget _submitButton() {
    return Opacity(
      opacity: _isSelfieUploadedSuccessfully ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: _isSelfieUploadedSuccessfully ? null : _submitAllKYC,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _isSelfieUploadedSuccessfully ? Colors.grey : _green,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              _isSelfieUploading ? "Submitting..." : (_isSelfieUploadedSuccessfully ? "Submitted ✓" : "Submit"),
              style: TextStyle(
                color: _isSelfieUploadedSuccessfully ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: _dmSans,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitAllKYC() {
    if (_selfieFile == null) {
      showToast("Please upload selfie", isError: true);
      return;
    }

    setState(() {
      _isSelfieUploading = true;
    });

    // Simulate selfie submission
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isSelfieUploading = false;
        _isSelfieUploadedSuccessfully = true;
      });
      showToast("Selfie submitted successfully!", isError: false);
    });
  }
}

// ─── KYC UPLOAD PAGE (ID Card / Passport / etc.) ─────────────────────────────
class KycUploadPage extends StatefulWidget {
  final String title;
  final KycObject? kyc;
  final IdVerificationType type;
  final MyProfileController controller;
  final ValueChanged<KycDetails> onUploaded;

  const KycUploadPage({
    required this.title,
    required this.kyc,
    required this.type,
    required this.controller,
    required this.onUploaded,
  });

  @override
  State<KycUploadPage> createState() => _KycUploadPageState();
}

class _KycUploadPageState extends State<KycUploadPage> {
  File? _frontImage;
  File? _backImage;
  File? _selfieImage;
  bool _isUploading = false;
  bool _isUploadedSuccessfully = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: _dmSans,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Front Side
                _uploadBox(
                  label: "Front Side of ID Card",
                  hint:
                      "Upload a valid government-issued ID (Passport,\nDriving License, or Aadhaar/National ID)",
                  file: _frontImage,
                  networkPath: widget.kyc?.frontImage,
                  onTap: () => _pickImage(isFront: true),
                ),
                const SizedBox(height: 12),
                _tipRow(
                  Icons.wb_sunny_outlined,
                  "Use good lighting for a clear photo.",
                ),
                _tipRow(
                  Icons.crop_free,
                  "Keep the entire document visible in the frame.",
                ),
                _tipRow(Icons.blur_off, "Avoid blur, glare, or shadows."),
                _tipRow(
                  Icons.upload_file_outlined,
                  "Upload in JPG, PNG, or PDF format",
                ),
                const SizedBox(height: 20),
                // Back Side
                _uploadBox(
                  label: "Back Side of ID Card",
                  hint:
                      "Upload a valid government-issued ID (Passport,\nDriving License, or Aadhaar/National ID)",
                  file: _backImage,
                  networkPath: widget.kyc?.backImage,
                  onTap: () => _pickImage(isFront: false),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          // Upload Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Opacity(
              opacity: _isUploadedSuccessfully ? 0.6 : 1.0,
              child: GestureDetector(
                onTap: _isUploadedSuccessfully ? null : (_onUpload),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isUploadedSuccessfully ? Colors.grey : _green,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      _isUploading ? "Uploading..." : (_isUploadedSuccessfully ? "Uploaded ✓" : "Upload"),
                      style: TextStyle(
                        color: _isUploadedSuccessfully ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadBox({
    required String label,
    required String hint,
    File? file,
    String? networkPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(10),
          dashPattern: [6, 4],
          strokeWidth: 1.5,
          color: _green.withOpacity(0.6), // yahan use karo
        ),
        child: Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: _secondary,
            borderRadius: BorderRadius.circular(10),
            //  border remove kar diya
          ),
          child: file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(file, fit: BoxFit.cover),
                )
              : (networkPath != null && networkPath.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(networkPath, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _green,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: _dmSans,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: const Icon(Icons.add, color: _green, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        hint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          fontFamily: _dmSans,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _tipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("• ", style: TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: _dmSans,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickImage({required bool isFront}) {
    showImageChooser(
      context,
      (chooseFile, isGallery) {
        final process = isGallery
            ? Future.value(chooseFile)
            : saveFileOnTempPath(
                chooseFile,
                onNewFile: (f) => setState(() {
                  if (isFront) {
                    _frontImage = f;
                  } else {
                    _backImage = f;
                  }
                  _isUploadedSuccessfully = false; // Re-enable upload button
                }),
              );
        if (isGallery) {
          setState(() {
            if (isFront) {
              _frontImage = chooseFile;
            } else {
              _backImage = chooseFile;
            }
            _isUploadedSuccessfully = false; // Re-enable upload button
          });
        }
      },
      isCrop: false,
      isGallery: true,
    );
  }

  void _onUpload() {
    if (_frontImage == null) {
      showToast("Front image cannot be empty", isError: true);
      return;
    }
    if (_backImage == null) {
      showToast("Back image cannot be empty", isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    widget.controller.uploadDocuments(
      widget.type,
      _frontImage!,
      _backImage!,
      File(""), // Selfie handled separately
      (kyc) {
        setState(() {
          _isUploading = false;
          _isUploadedSuccessfully = true;
        });
        showToast("Document uploaded successfully!", isError: false);
        Future.delayed(const Duration(seconds: 2), () {
          widget.onUploaded(kyc);
          Navigator.pop(context);
        });
      },
    );
  }
}
