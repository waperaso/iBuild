// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageLabel => 'Language';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get commonExit => 'Exit';

  @override
  String get logoutConfirmTitle => 'Sign out?';

  @override
  String get logoutConfirmMessage =>
      'You\'ll need to sign in again to access your account.';

  @override
  String get loginTitle => 'Admin sign in';

  @override
  String get loginSubtitle => 'Platform and residence (ЖК) administration';

  @override
  String get loginPhoneHint => 'Phone number';

  @override
  String get loginSendCode => 'Send code';

  @override
  String get loginSendCodeError => 'Could not send code. Try again.';

  @override
  String get otpTitle => 'Enter code';

  @override
  String otpSentTo(String phone) {
    return 'Sent to $phone';
  }

  @override
  String get otpHint => '000000';

  @override
  String get otpDevHelper => 'Dev: 123456 when Eskiz is not configured';

  @override
  String get otpVerify => 'Verify';

  @override
  String get otpInvalidError => 'Invalid or expired code';

  @override
  String get otpResendPrompt => 'Didn\'t get the code?';

  @override
  String get otpResendAction => 'Resend code';

  @override
  String otpResendCountdown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get otpResendSuccess => 'New code sent';

  @override
  String otpResendError(String error) {
    return 'Couldn\'t resend the code: $error';
  }

  @override
  String get applyStepWelcome => 'Welcome';

  @override
  String get applyStepRole => 'Your role';

  @override
  String get applyStepDetails => 'Company details';

  @override
  String get applyOnboardingTitle => 'Set up residence access';

  @override
  String get applyOnboardingSubtitle =>
      'A short setup so your team can manage complexes, units, and leads. Platform review usually takes one business day.';

  @override
  String get applyOnboardingPointWorkspace =>
      'One workspace per company for your residences';

  @override
  String get applyOnboardingPointAccess =>
      'Access opens after a quick platform check';

  @override
  String get applyGetStarted => 'Get started';

  @override
  String get applyHaveAccount => 'I have an account';

  @override
  String get authHeroTitle => 'Built for property developers';

  @override
  String get authHeroSubtitle =>
      'Manage residential complexes, units, and buyer leads in one iBuild workspace — built for teams, not just admins.';

  @override
  String get authHeroPointVerified =>
      'Verified developers and projects earn buyer trust';

  @override
  String get authHeroPointLeads =>
      'Buyer and tenant leads land straight in your CRM';

  @override
  String get applyRoleTitle => 'Developer registration';

  @override
  String get applyRoleSubtitle =>
      'Publish your residential complexes and manage units & buyer leads. If you also build your own projects, check the box below.';

  @override
  String get applyContinue => 'Continue';

  @override
  String get applyKindDeveloperLabel => 'Property developer';

  @override
  String get applyKindDeveloperSubtitle =>
      'You build and sell your own residential complexes — publish projects and manage units & buyer leads.';

  @override
  String get applyKindConstructionLabel => 'Construction company';

  @override
  String get applyKindConstructionSubtitle =>
      'You build for other developers (contractor) — coordinate on-site work, inventory, and residence access.';

  @override
  String get applyAlsoContractorLabel => 'I also build the projects myself';

  @override
  String get applyAlsoContractorSubtitle =>
      'Check this if you\'re a developer who also acts as the contractor on your own sites — you\'ll need a construction license number.';

  @override
  String get applyDetailsTitle => 'Legal entity details';

  @override
  String applyDetailsSubtitle(String kind) {
    return 'Uzbekistan registration data (STIR/INN, director PINFL, UBO). Required for platform review as $kind.';
  }

  @override
  String get applyBrandName => 'Brand / trade name *';

  @override
  String get applyLegalName => 'Full legal name *';

  @override
  String get applyInn => 'ИНН / STIR (9 digits) *';

  @override
  String get applyLegalForm => 'Legal form (LLC / ИП / JSC) *';

  @override
  String get applyRegistrationNumber => 'State registration number';

  @override
  String get applyLegalAddress => 'Legal address *';

  @override
  String get applyOfficeAddress => 'Office / sales office address';

  @override
  String get applyRegion => 'Region';

  @override
  String get applyRegionTashkent => 'Tashkent';

  @override
  String get applyRegionNewTashkent => 'New Tashkent';

  @override
  String get applyEmail => 'Company email';

  @override
  String get applyDirectorSectionTitle => 'Director (holder)';

  @override
  String get applyDirectorFullName => 'Director full name *';

  @override
  String get applyDirectorPinfl => 'Director PINFL (14 digits) *';

  @override
  String get applyDirectorPassport => 'Passport series & number';

  @override
  String get applyDirectorPhone => 'Director phone';

  @override
  String get applyUboName => 'Ultimate beneficial owner (if different)';

  @override
  String get applyLicense => 'Construction license number';

  @override
  String get applyUboConfirm =>
      'I confirm beneficial-owner (UBO) details are accurate (AML / UZ registration rules). *';

  @override
  String get applyUboHelper =>
      'A UBO (ultimate beneficial owner) is the individual who ultimately owns or controls the company — usually anyone holding 25% or more. Uzbek AML rules require this to be declared.';

  @override
  String get applySubmit => 'Save draft';

  @override
  String get applySaveDraft => 'Save draft';

  @override
  String get applySaveDraftSuccess =>
      'Draft saved — review your details, then submit for approval when ready.';

  @override
  String get applySubmitSuccess =>
      'Application submitted — awaiting platform approval.';

  @override
  String get applyDraftTitle => 'Draft saved';

  @override
  String get applyDraftSubtitle =>
      'Review your details and submit the application for platform review when you are ready.';

  @override
  String get applySubmitForReview => 'Submit for review';

  @override
  String get applySubmitForReviewSuccess =>
      'Application submitted — awaiting platform review.';

  @override
  String get applyDocumentsRequiredHint =>
      'Upload all 4 verification documents above before submitting your application for review.';

  @override
  String applyDocumentsMissingHint(String names) {
    return 'You haven\'t added: $names. Upload them above before submitting your application for review.';
  }

  @override
  String get applyReviewDecisionLabel => 'Decision';

  @override
  String get applyPendingTitle => 'Application submitted';

  @override
  String get applyPendingSubtitle =>
      'We\'ll review your application and notify you here. This usually takes one business day.';

  @override
  String get applyPendingRefresh => 'Refresh status';

  @override
  String get applyRejectedTitle => 'Application declined';

  @override
  String get applyRejectedReasonLabel => 'Reason for decline';

  @override
  String get applyRejectedResendAction => 'Edit & resubmit';

  @override
  String get applyApprovedTitle => 'Application approved';

  @override
  String get applyApprovedSubtitle => 'Redirecting to your workspace…';

  @override
  String applyRequestFailed(String code) {
    return 'Request failed ($code). Try again.';
  }

  @override
  String get applyNetworkError =>
      'Could not reach the server. Check your connection.';

  @override
  String get navPlatform => 'Platform';

  @override
  String get navResidence => 'Residence';

  @override
  String get navOrganization => 'Organization';

  @override
  String get navSettings => 'Settings';

  @override
  String get shellAdminFallback => 'Admin';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsPalette => 'Color theme';

  @override
  String get settingsAccount => 'Account';

  @override
  String get platformTitle => 'Platform administration';

  @override
  String get platformSubtitle =>
      'Approve companies, moderate projects, track \$299/mo subscriptions.';

  @override
  String platformAnalyticsError(String error) {
    return 'Analytics error: $error';
  }

  @override
  String get statUsers => 'Users';

  @override
  String get statProjects => 'Projects';

  @override
  String get statPublished => 'Published';

  @override
  String get statLeads => 'Leads';

  @override
  String get statAppsPending => 'Apps pending';

  @override
  String get statProjectsPending => 'Projects pending';

  @override
  String get statPaid => 'Paid';

  @override
  String get statUnpaid => 'Unpaid';

  @override
  String get platformBusinessesSectionTitle =>
      'Registered businesses · payment';

  @override
  String get platformNoBusinesses => 'No registered businesses yet';

  @override
  String platformBusinessesError(String error) {
    return 'Businesses error: $error';
  }

  @override
  String get platformPendingAppsSectionTitle => 'Pending applications';

  @override
  String get platformNoPendingApps => 'No pending applications';

  @override
  String get platformViewKyc => 'View KYC';

  @override
  String get platformApprove => 'Approve';

  @override
  String get platformReject => 'Reject';

  @override
  String get platformRejectReasonDefault => 'Does not meet requirements';

  @override
  String get devStatusPending => 'Waiting for review';

  @override
  String get devStatusDraft => 'Draft';

  @override
  String get devStatusInReview => 'On review';

  @override
  String get devStatusApproved => 'Approved';

  @override
  String get devStatusRejected => 'Declined';

  @override
  String get platformChangeStatusTooltip => 'Change status';

  @override
  String get platformStatusMenuAccept => 'Accept';

  @override
  String get platformStatusMenuDecline => 'Decline…';

  @override
  String get platformStatusUpdated => 'Application status updated';

  @override
  String get platformDeclineDialogTitle => 'Decline application';

  @override
  String get platformDeclineReasonLabel => 'Reason';

  @override
  String get platformDeclineReasonHint =>
      'Why is this application being declined?';

  @override
  String get platformDeclineConfirm => 'Decline application';

  @override
  String get platformPendingProjectsSectionTitle =>
      'Projects pending moderation';

  @override
  String get platformNoPendingProjects => 'No projects awaiting moderation';

  @override
  String get platformPublish => 'Publish';

  @override
  String get platformProjectDetails => 'Details';

  @override
  String get platformProjectDescriptionLabel => 'Description';

  @override
  String get platformProjectPricingLabel => 'Pricing';

  @override
  String platformProjectPriceRange(String min, String max) {
    return '$min – $max UZS';
  }

  @override
  String platformProjectRentRange(String min, String max) {
    return 'Rent: $min – $max UZS / mo';
  }

  @override
  String platformProjectCompletionLabel(String date) {
    return 'Completion: $date';
  }

  @override
  String get platformProjectGalleryLabel => 'Gallery';

  @override
  String get platformProjectUnitsLabel => 'Units';

  @override
  String platformProjectUnitsSummary(int buildings, int total) {
    return '$buildings buildings · $total units';
  }

  @override
  String get platformProjectUnitsEmpty => 'No units added yet';

  @override
  String platformProjectLoadError(String error) {
    return 'Failed to load project details: $error';
  }

  @override
  String get platformPublishedProjectsSectionTitle => 'Published projects';

  @override
  String get platformNoPublishedProjects => 'No published projects';

  @override
  String get platformUnpublish => 'Unpublish';

  @override
  String get platformWarn => 'Warn';

  @override
  String platformWarnDialogTitle(String name) {
    return 'Warning for \"$name\"';
  }

  @override
  String get platformWarnReasonHint => 'What should the developer fix?';

  @override
  String get platformUnpublishConfirm => 'Unpublish';

  @override
  String get platformActionSuccess => 'Done';

  @override
  String platformActionError(String error) {
    return 'Error: $error';
  }

  @override
  String get platformPendingReviewsSectionTitle => 'Reviews pending moderation';

  @override
  String get platformNoPendingReviews => 'No reviews awaiting moderation';

  @override
  String get platformReviewRatingLocation => 'Location';

  @override
  String get platformReviewRatingQuality => 'Quality';

  @override
  String get platformReviewRatingValue => 'Value';

  @override
  String platformReviewProjectLabel(String name) {
    return 'Project: $name';
  }

  @override
  String get platformAnonymous => 'Anonymous';

  @override
  String get platformKeep => 'Keep';

  @override
  String get platformRemove => 'Remove';

  @override
  String get platformPendingRentalsSectionTitle =>
      'Owner rental listings pending moderation';

  @override
  String get platformNoPendingRentals =>
      'No rental listings awaiting moderation';

  @override
  String get platformRentalRejectNoteDefault =>
      'Does not meet listing requirements';

  @override
  String platformRentalMonthlyRent(String amount) {
    return '$amount UZS / mo';
  }

  @override
  String platformRentalContactLabel(String phone) {
    return 'Contact: $phone';
  }

  @override
  String get platformAuditLogSectionTitle => 'Audit log';

  @override
  String get platformNoAuditEvents => 'No audit events yet';

  @override
  String platformAuditError(String error) {
    return 'Audit log error: $error';
  }

  @override
  String get platformAuditLogActorPrefix => 'Changed by';

  @override
  String get platformAuditLogActorUnknown => 'Unknown user';

  @override
  String platformAuditLogPageInfo(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get platformAuditLogPrevPage => 'Previous page';

  @override
  String get platformAuditLogNextPage => 'Next page';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Every project change and submitted document that needs your review.';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsSectionTitle => 'All notifications';

  @override
  String notificationsUnreadSectionTitle(int count) {
    return '$count unread';
  }

  @override
  String notificationsError(String error) {
    return 'Notifications error: $error';
  }

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptySubtitle =>
      'New projects, edits, and submitted documents will show up here.';

  @override
  String get notificationsJustNow => 'Just now';

  @override
  String notificationsMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String notificationsHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String notificationsDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get platformUsersSectionTitle => 'Users & roles';

  @override
  String get platformColPhone => 'Phone';

  @override
  String get platformColRole => 'Role';

  @override
  String get platformColStatus => 'Status';

  @override
  String get platformColActions => 'Actions';

  @override
  String platformBannedTooltip(String by, String reason) {
    return 'Banned by $by: $reason';
  }

  @override
  String get platformBannedLabel => 'Banned';

  @override
  String get platformSetRoleTooltip => 'Set role';

  @override
  String get platformSetRoleLabel => 'Set role';

  @override
  String get platformUnban => 'Unban';

  @override
  String get platformBan => 'Ban';

  @override
  String get platformDeleteAdminTooltip => 'Delete platform admin account';

  @override
  String platformDeleteAdminConfirmTitle(String phone) {
    return 'Delete $phone?';
  }

  @override
  String get platformDeleteAdminConfirmBody =>
      'This permanently removes their platform-admin account and signs them out everywhere. This can\'t be undone.';

  @override
  String get platformDeleteAdminConfirm => 'Delete account';

  @override
  String get platformDeleteAdminSelfHint =>
      'This is your own account — sign in as another admin to remove it.';

  @override
  String platformBanDialogTitle(String phone) {
    return 'Ban $phone';
  }

  @override
  String get platformBanDialogUserFallback => 'user';

  @override
  String get platformBanDialogBody =>
      'This freezes the account everywhere except its own profile and signing out.';

  @override
  String get platformBanReasonLabel => 'Reason';

  @override
  String get platformBanReasonHint => 'Why is this account being banned?';

  @override
  String get platformBanByLabel => 'Banned by (name)';

  @override
  String get platformBanByHint => 'Shown to the user on their account';

  @override
  String get platformBanConfirm => 'Ban account';

  @override
  String get accountBannedTitle => 'Your account has been banned';

  @override
  String get accountBannedBody =>
      'This account is frozen. You can only view this notice and sign out until a platform admin lifts the ban.';

  @override
  String get accountBannedReasonLabel => 'Reason';

  @override
  String accountBannedByLabel(String name) {
    return 'Banned by $name';
  }

  @override
  String platformKycTitle(String name) {
    return 'KYC · $name';
  }

  @override
  String get kycCompanyName => 'Company name';

  @override
  String get kycLegalName => 'Legal name';

  @override
  String get kycAccountKind => 'Account kind';

  @override
  String get kycLegalForm => 'Legal form';

  @override
  String get kycInn => 'INN';

  @override
  String get kycRegistrationNumber => 'Registration number';

  @override
  String get kycOkedCode => 'OKED code';

  @override
  String get kycLegalAddress => 'Legal address';

  @override
  String get kycOfficeAddress => 'Office address';

  @override
  String get kycRegion => 'Region';

  @override
  String get kycEmail => 'Email';

  @override
  String get kycWebsite => 'Website';

  @override
  String get kycDirectorFullName => 'Director full name';

  @override
  String get kycDirectorPinfl => 'Director PINFL';

  @override
  String get kycDirectorPassport => 'Director passport';

  @override
  String get kycDirectorPhone => 'Director phone';

  @override
  String get kycDirectorEmail => 'Director email';

  @override
  String get kycUboDeclared => 'UBO declared';

  @override
  String get kycUboFullName => 'UBO full name';

  @override
  String get kycUboHelper =>
      'Ultimate beneficial owner — the individual who ultimately owns or controls the company (typically ≥25%).';

  @override
  String get kycConstructionLicense => 'Construction license';

  @override
  String get platformKycDocumentsTitle => 'Documents';

  @override
  String get platformKycDocumentsEmpty => 'No documents uploaded yet';

  @override
  String platformKycDocumentsError(String error) {
    return 'Documents error: $error';
  }

  @override
  String get platformKycDocumentView => 'View';

  @override
  String get platformKycDocumentAccept => 'Accept';

  @override
  String get platformKycDocumentReject => 'Reject';

  @override
  String get platformKycDocumentRejectDialogTitle => 'Reject document';

  @override
  String get platformKycDocumentRejectReasonHint =>
      'Why is this document being rejected?';

  @override
  String get residenceNewProjectDialogTitle => 'New project';

  @override
  String get residenceNameHint => 'Name';

  @override
  String get residenceTypeHint => 'Property type';

  @override
  String get projectTypeResidentialComplex => 'Residential complex';

  @override
  String get projectTypeBusinessCentre => 'Business centre';

  @override
  String get projectTypeStreetRetail => 'Street retail';

  @override
  String get projectTypeOffice => 'Office';

  @override
  String get projectTypeCottage => 'Cottage';

  @override
  String get residenceDistrictHint => 'District';

  @override
  String get residenceDistrictOther => 'Other (specify)';

  @override
  String get residenceDistrictOtherHint => 'District / area name';

  @override
  String get residenceAddressHint => 'Address (street, building)';

  @override
  String get mapLocationTapHint => 'Tap the map to set the property location';

  @override
  String get mapLocationManualHint => 'Or type exact coordinates';

  @override
  String get mapLocationLatitudeLabel => 'Latitude';

  @override
  String get mapLocationLongitudeLabel => 'Longitude';

  @override
  String get mapLocationApplyCoordinates => 'Apply';

  @override
  String get mapLocationInvalidCoordinates =>
      'Enter a valid latitude (-90 to 90) and longitude (-180 to 180)';

  @override
  String mapLocationCoordinates(String lat, String lng) {
    return 'Coordinates: $lat, $lng';
  }

  @override
  String get mapLocationZoomIn => 'Zoom in';

  @override
  String get mapLocationZoomOut => 'Zoom out';

  @override
  String get residenceCreate => 'Create';

  @override
  String get residenceCreatedSnackbar =>
      'Project saved as draft — submit for moderation when ready';

  @override
  String residencePublishingLocked(String price) {
    return 'Publishing is locked until you subscribe (\$$price/mo). You can still configure your organization profile.';
  }

  @override
  String get residenceTitle => 'Residence admin';

  @override
  String get residenceSubtitle =>
      'Manage inventory, unit status, media URLs, and lead CRM.';

  @override
  String get residenceNewProject => 'New project';

  @override
  String get residenceProjectsSectionTitle => 'Your projects';

  @override
  String get residenceNoProjects => 'No projects yet';

  @override
  String get residenceNoProjectsSubtitle =>
      'Create one, then wait for platform approval.';

  @override
  String residenceLoadError(String error) {
    return 'Load error (need approved developer + residence_admin role): $error';
  }

  @override
  String residenceProjectMeta(
    String district,
    String moderation,
    String published,
  ) {
    return '$district · moderation: $moderation · published: $published';
  }

  @override
  String get orgPlanUnlimited => 'unlimited';

  @override
  String get orgPlanActive => 'Active';

  @override
  String get orgPlanCurrentPlan => 'Current plan';

  @override
  String get orgPlanSubscribe => 'Subscribe';

  @override
  String orgPlanSummary(
    String price,
    String maxProjects,
    String maxUnits,
    String leads,
    String payPerLead,
  ) {
    return '\$$price/mo · $maxProjects projects · $maxUnits units · $leads leads incl. · \$$payPerLead/lead after';
  }

  @override
  String get orgTitle => 'Organization profile';

  @override
  String get orgSubtitle =>
      'Configure how your company and residences appear. Publishing to buyers requires an active \$299/mo subscription.';

  @override
  String get orgNoProfile => 'No organization profile yet.';

  @override
  String orgError(String error) {
    return 'Error: $error';
  }

  @override
  String orgLegalLine(String legalName, String inn) {
    return '$legalName · ИНН $inn';
  }

  @override
  String orgPaymentLabel(String status) {
    return 'Payment: $status';
  }

  @override
  String get orgPublishingUnlocked => ' · publishing unlocked';

  @override
  String get orgPublishingLocked => ' · publishing locked';

  @override
  String get orgSubscriptionPlansTitle => 'Subscription plans';

  @override
  String get orgSubscriptionPlansSubtitle =>
      'Choose a tier for how many projects/units you publish and how many leads are included before pay-per-lead applies.';

  @override
  String orgPlansError(String error) {
    return 'Plans error: $error';
  }

  @override
  String get orgDocumentsTitle => 'Verification documents';

  @override
  String get orgDocumentsSubtitle =>
      'Upload all 4 required documents and get each accepted by the platform team before your Verified badge appears to buyers.';

  @override
  String orgDocumentsError(String error) {
    return 'Documents error: $error';
  }

  @override
  String get orgDocumentNotUploaded => 'Not uploaded';

  @override
  String get orgDocumentUpload => 'Upload';

  @override
  String get orgDocumentReplace => 'Replace';

  @override
  String orgDocumentUploading(int percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get orgDocumentUploaded =>
      'Document uploaded — pending platform review.';

  @override
  String orgDocumentUploadError(String error) {
    return 'Upload failed: $error';
  }

  @override
  String orgDocumentRejectReason(String reason) {
    return 'Rejected: $reason';
  }

  @override
  String get orgDocumentView => 'View';

  @override
  String get orgDocumentConfirmTitle => 'Confirm before sending';

  @override
  String orgDocumentConfirmMessage(String type) {
    return 'Review this $type carefully — once you send it, the platform team will see it for review.';
  }

  @override
  String get orgDocumentConfirmSend => 'Send for review';

  @override
  String get orgDocumentOptionalSectionTitle => 'Optional documents';

  @override
  String get orgDocumentOptionalBadge => 'Optional';

  @override
  String get orgPublicPresenceTitle => 'Public presence';

  @override
  String get orgAboutHint => 'About your organization / residences';

  @override
  String get orgOfficeHint => 'Sales office address';

  @override
  String get orgWebsiteHint => 'Website';

  @override
  String get orgLogoHint => 'Logo image URL';

  @override
  String get orgCoverHint => 'Cover image URL';

  @override
  String get orgBrandColorHint => 'Brand color (e.g. #1A1A1A)';

  @override
  String get orgSaveProfile => 'Save profile';

  @override
  String get orgSavedMessage => 'Profile saved.';

  @override
  String get orgPlanDetailsShow => 'Show visibility details';

  @override
  String get orgPlanDetailsHide => 'Hide visibility details';

  @override
  String get orgPlanAlwaysOnTopTitle => '\"Always on Top\" visibility';

  @override
  String get orgPlanAlwaysOnTopSubtitle =>
      'While your subscription is active, listings rank with a boost coefficient of 0.4. When it lapses, the boost decays to 0.04 over the two weeks after expiry.';

  @override
  String get orgPlanDecayActiveLegend => 'Active (0.4)';

  @override
  String get orgPlanDecayExpiredLegend => 'After expiry (→0.04)';

  @override
  String get orgPlanDecayWeeksAxis => 'Weeks from expiry';

  @override
  String get orgPlanDecayCoefficientAxis => 'Boost';

  @override
  String get orgAiSectionTitle => 'Draft description template';

  @override
  String get orgAiSectionSubtitle =>
      'Add your links and an optional company deck to compose a starter draft from a template — this is not AI-written — then edit it to fit your business before saving.';

  @override
  String get orgAiWebsiteHint => 'Website URL';

  @override
  String get orgAiInstagramHint => 'Instagram URL';

  @override
  String get orgAiPickPdf => 'Attach company PDF';

  @override
  String orgAiPdfSelected(String name) {
    return 'Attached: $name';
  }

  @override
  String get orgAiGenerate => 'Compose draft template';

  @override
  String get orgAiGenerating => 'Composing…';

  @override
  String get orgAiApply => 'Use this draft';

  @override
  String get orgAiResultHint => 'Draft template (editable)';

  @override
  String get orgAiNoInputs => 'Add a website, Instagram, or PDF first.';

  @override
  String get orgAiApplied => 'Draft applied — review and save.';

  @override
  String get projectLoadError => 'Could not load project';

  @override
  String get projectBack => 'Back';

  @override
  String projectModerationLabel(String status) {
    return 'Moderation: $status';
  }

  @override
  String get projectModerationStatusDraft => 'Draft';

  @override
  String get projectModerationStatusPending => 'Pending review';

  @override
  String get projectModerationStatusRejected => 'Rejected';

  @override
  String get projectSubmitForReview => 'Submit for review';

  @override
  String get projectDraftBanner =>
      'This residence is saved as a draft. Fill in the details and submit for platform moderation when ready.';

  @override
  String get projectRejectedBanner =>
      'This residence was declined. Fix the issues noted by the platform and submit again.';

  @override
  String get projectWarningBanner => 'Platform warning';

  @override
  String get projectWarningBannerSubtitle =>
      'Address the notes below. The listing stays published until the platform unpublishes it.';

  @override
  String get residenceProjectWarned => 'Platform warning';

  @override
  String get projectUnpublish => 'Unpublish';

  @override
  String get projectPublish => 'Publish';

  @override
  String get projectRepublish => 'Republish';

  @override
  String get projectUnpublishConfirm =>
      'This residence will disappear from the B2C catalogue. Continue?';

  @override
  String get projectPublishSuccess =>
      'Residence is live in the catalogue again';

  @override
  String get projectUnpublishSuccess => 'Residence unpublished';

  @override
  String get projectDelete => 'Delete residence';

  @override
  String projectDeleteConfirmTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get projectDeleteConfirmBody =>
      'This cannot be undone: buildings, units, offers, and leads for this residence will be removed.';

  @override
  String get projectDeleteSuccess => 'Residence deleted';

  @override
  String get projectPublishNeedsReview =>
      'Submit this residence for platform review first';

  @override
  String get projectPublishNeedsSubscription =>
      'An active subscription is required to publish';

  @override
  String get navActiveProjects => 'Active residences';

  @override
  String get activeProjectsTitle => 'Active residences';

  @override
  String get activeProjectsSubtitle =>
      'Live catalogue listings — warnings and unpublish actions.';

  @override
  String get projectSubmitForReviewSuccess =>
      'Submitted for moderation — awaiting platform review.';

  @override
  String get projectLocationSectionTitle => 'Map location';

  @override
  String get projectLocationSave => 'Save location';

  @override
  String get projectLocationSaved => 'Location saved';

  @override
  String projectPublishedLabel(String value) {
    return 'Published: $value';
  }

  @override
  String get publishedYes => 'Yes';

  @override
  String get publishedNo => 'No';

  @override
  String platformProjectDeveloper(String name) {
    return 'Developer: $name';
  }

  @override
  String get projectAnalyticsTitle => 'Analytics';

  @override
  String get projectOffersTitle => 'Offers';

  @override
  String get projectAddOffer => 'Add offer';

  @override
  String get projectNoOffers => 'No active offers';

  @override
  String get projectNoOffersSubtitle =>
      'Add a discount, installment plan, or rent promo.';

  @override
  String get projectRemoveOfferTooltip => 'Remove offer';

  @override
  String get projectUnitsTitle => 'Units';

  @override
  String get projectAddBuilding => 'Add building';

  @override
  String get projectBulkAddUnits => 'Bulk add units';

  @override
  String get projectViewToggleList => 'List view';

  @override
  String get projectViewToggleChessboard => 'Chessboard view';

  @override
  String get projectBuildingFallback => 'Building';

  @override
  String projectUnitLabel(String number) {
    return 'Unit $number';
  }

  @override
  String projectUnitLabelWithStatus(String number, String status) {
    return 'Unit $number · $status';
  }

  @override
  String projectUnitMetaLine(
    String kind,
    String dealType,
    String status,
    String mediaCount,
  ) {
    return '$kind · $dealType · $status · media: $mediaCount';
  }

  @override
  String projectUnitMetaLineNoStatus(
    String kind,
    String dealType,
    String mediaCount,
  ) {
    return '$kind · $dealType · media: $mediaCount';
  }

  @override
  String get projectAddMediaUrl => 'Add media URL';

  @override
  String get projectStatusButton => 'Status';

  @override
  String get projectChangeStatusButton => 'Change status';

  @override
  String get projectLeadCrmTitle => 'Lead CRM';

  @override
  String get projectKanbanHint =>
      'Drag a card into another column to update its status.';

  @override
  String get projectNoLeads => 'No leads yet';

  @override
  String projectLeadSummary(String number, String intent, String status) {
    return '$number · $intent · $status';
  }

  @override
  String projectLeadContactLine(String phone, String message) {
    return '$phone · $message';
  }

  @override
  String get projectUpdateLeadStatus => 'Update';

  @override
  String get projectTagsScoreTooltip => 'Tags & score';

  @override
  String get projectNewBuildingDialogTitle => 'Add building';

  @override
  String get projectBuildingNameLabel => 'Name';

  @override
  String get projectFloorsLabel => 'Floors';

  @override
  String get projectMediaUrlHint => 'https://...';

  @override
  String get projectAddBuildingFirstSnackbar => 'Add a building first';

  @override
  String projectUnitsAddedSnackbar(String count) {
    return 'Added $count units';
  }

  @override
  String projectUnitsPartiallyAddedSnackbar(String count, String error) {
    return 'Stopped after adding $count units: $error';
  }

  @override
  String get projectOfferEditorTitle => 'Add offer';

  @override
  String get projectOfferTypeLabel => 'Type';

  @override
  String get projectOfferTitleLabel => 'Title';

  @override
  String get projectOfferDescriptionLabel => 'Description';

  @override
  String get projectDownPaymentLabel => 'Down payment %';

  @override
  String get projectTermMonthsLabel => 'Term (months)';

  @override
  String get projectInterestRateLabel => 'Interest rate %';

  @override
  String get projectBulkUnitsDialogTitle => 'Bulk add units';

  @override
  String get projectBuildingLabel => 'Building';

  @override
  String get projectFloorFromLabel => 'Floor from';

  @override
  String get projectFloorToLabel => 'Floor to';

  @override
  String get projectUnitsPerFloorLabel => 'Units per floor';

  @override
  String get projectStartingNumberLabel => 'Starting number';

  @override
  String get projectKindLabel => 'Kind';

  @override
  String get projectDealLabel => 'Deal';

  @override
  String get projectAreaLabel => 'Area (m²)';

  @override
  String get projectRoomsLabel => 'Rooms';

  @override
  String get projectPriceLabel => 'Price (\$)';

  @override
  String get projectPriceM2Label => 'Price/m²';

  @override
  String get chessboardFilterAll => 'All types';

  @override
  String get chessboardRoomsLegendTitle => 'Rooms:';

  @override
  String get chessboardRooms4Plus => '4+';

  @override
  String get projectRentLabel => 'Rent/mo (\$)';

  @override
  String get projectGenerate => 'Generate';

  @override
  String get projectLegendSoldRented => 'sold / rented';

  @override
  String get projectLeadsStat => 'Leads (30d)';

  @override
  String get projectLeadsTotalStat => 'Leads total';

  @override
  String get projectSellThroughStat => 'Sell-through';

  @override
  String get projectMonthsToSellOutStat => 'Est. months to sell out';

  @override
  String get projectUnitsStat => 'Units';

  @override
  String get projectLeadFunnelTitle => 'Lead funnel';

  @override
  String get projectUnitsByStatusTitle => 'Units by status';

  @override
  String get projectPhotoReportsTitle => 'Construction photo reports';

  @override
  String get projectPhotoReportsSubtitle =>
      'Dated site photos grouped by month, optionally tagged with a construction-progress percentage.';

  @override
  String get projectAddPhotoReport => 'Add photo';

  @override
  String get projectPhotoReportsEmpty => 'No photo reports yet';

  @override
  String projectPhotoReportUploading(int percent) {
    return 'Uploading… $percent%';
  }

  @override
  String projectPhotoReportUploadError(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get projectPhotoReportDialogTitle => 'Add photo report';

  @override
  String get projectPhotoReportDateLabel => 'Date taken';

  @override
  String get projectPhotoReportProgressLabel =>
      'Construction progress % (optional)';

  @override
  String get projectPhotoReportDeleteTooltip => 'Remove photo report';

  @override
  String projectPhotoReportProgressBadge(int percent) {
    return '$percent%';
  }

  @override
  String get statusAvailable => 'available';

  @override
  String get statusReserved => 'reserved';

  @override
  String get statusSold => 'sold';

  @override
  String get statusRented => 'rented';

  @override
  String get statusBlocked => 'blocked';

  @override
  String get offerTypeDiscount => 'discount';

  @override
  String get offerTypeInstallment => 'installment';

  @override
  String get offerTypeRentPromo => 'rent promo';

  @override
  String get unitKindApartment => 'apartment';

  @override
  String get unitKindOffice => 'office';

  @override
  String get unitKindRetail => 'retail';

  @override
  String get dealTypeSale => 'sale';

  @override
  String get dealTypeRent => 'rent';

  @override
  String get leadScoreHot => 'hot';

  @override
  String get leadScoreWarm => 'warm';

  @override
  String get leadScoreCold => 'cold';

  @override
  String get leadStatusNew => 'new';

  @override
  String get leadStatusContacted => 'contacted';

  @override
  String get leadStatusScheduled => 'scheduled';

  @override
  String get leadStatusVisited => 'visited';

  @override
  String get leadStatusWon => 'won';

  @override
  String get leadStatusLost => 'lost';

  @override
  String get roleOrdinaryUser => 'ordinary user';

  @override
  String get roleResidenceAdmin => 'residence admin';

  @override
  String get roleSystemAdmin => 'system admin';

  @override
  String get leadStatusQualified => 'qualified';

  @override
  String get documentTypeLicense => 'License';

  @override
  String get documentTypeLicenseHint =>
      'Construction business license proving the company is legally allowed to act as a developer.';

  @override
  String get documentTypeConstructionPermit => 'Construction permit';

  @override
  String get documentTypeConstructionPermitHint =>
      'Official local-authority permit to build this specific project.';

  @override
  String get documentTypeLandRights => 'Land rights';

  @override
  String get documentTypeLandRightsHint =>
      'Document proving ownership or long-term lease rights to the land the project is built on.';

  @override
  String get documentTypeProjectDeclaration => 'Project declaration';

  @override
  String get documentTypeProjectDeclarationHint =>
      'Declaration describing the project — timeline, specifications and the developer — typically required for off-plan sales.';

  @override
  String get documentTypeCadastre => 'Cadastre';

  @override
  String get documentTypeCadastreHint =>
      'Cadastral passport for the plot, with its exact boundaries and registry data.';

  @override
  String get documentStatusPending => 'Pending review';

  @override
  String get documentStatusAccepted => 'Accepted';

  @override
  String get documentStatusRejected => 'Rejected';

  @override
  String get navModeration => 'Moderation';

  @override
  String get navCrm => 'CRM';

  @override
  String get navTickets => 'Tickets';

  @override
  String get moderationTitle => 'Moderation';

  @override
  String get moderationSubtitle =>
      'New residence submissions awaiting review, and flagged reviews.';

  @override
  String get adminProjectsTitle => 'ЖК administration';

  @override
  String get adminProjectsSubtitle =>
      'Every residential complex / business centre on the platform — browse how each one is furnished and attached. A system admin never owns a project.';

  @override
  String get adminProjectsFilterAll => 'All';

  @override
  String get adminProjectsFilterPending => 'Pending';

  @override
  String get adminProjectsFilterApproved => 'Approved';

  @override
  String get adminProjectsFilterRejected => 'Rejected';

  @override
  String get adminProjectsEmpty => 'No projects match this filter';

  @override
  String adminProjectsMeta(int count, String units) {
    return '$count photos · $units units';
  }

  @override
  String get adminProjectsUnpublished => 'Unpublished';

  @override
  String get crmTitle => 'CRM';

  @override
  String get crmSubtitle =>
      'Every lead across every ЖК — platform-wide demand, not just one project\'s pipeline.';

  @override
  String get crmKanbanHint =>
      'Drag a card into another column to update its status.';

  @override
  String get crmSearchHint => 'Search by phone, project, or manager';

  @override
  String get crmEmpty => 'No leads match this filter';

  @override
  String get crmEdit => 'Edit';

  @override
  String crmAssignedTo(String name) {
    return 'Assigned to $name';
  }

  @override
  String get crmStatusLabel => 'Status';

  @override
  String get crmScoreLabel => 'Score';

  @override
  String get crmAssignedManagerLabel => 'Assigned manager';

  @override
  String get crmNotesLabel => 'Notes';

  @override
  String get crmOwnerLabel => 'Owner';

  @override
  String get crmOwnerUnassigned => 'Unassigned';

  @override
  String get crmOwnerFilterAll => 'All leads';

  @override
  String get crmOwnerFilterMine => 'My leads';

  @override
  String get crmOwnerFilterUnassigned => 'Unassigned';

  @override
  String get crmAssignToMe => 'Assign to me';

  @override
  String get crmAssigneesLoadError => 'Could not load managers';

  @override
  String get crmTransferLabel => 'Transfer to';

  @override
  String get crmTransferHint => 'Hand off to another manager';

  @override
  String get crmTransferNone => 'No transfer';

  @override
  String get crmTransferNoteLabel => 'Transfer note';

  @override
  String get crmLeadEditorTitle => 'Lead CRM';

  @override
  String get crmTagsLabel => 'Tags (comma-separated)';

  @override
  String get crmEventHistoryTitle => 'Activity';

  @override
  String get crmEventHistoryEmpty => 'No activity yet';

  @override
  String get crmEventAssigned => 'Assigned';

  @override
  String get crmEventTransferred => 'Transferred';

  @override
  String get crmEventUnassigned => 'Unassigned';

  @override
  String crmEventStatusChanged(String detail) {
    return 'Status: $detail';
  }

  @override
  String get crmEventNote => 'Note added';

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get ticketsSubtitle =>
      'Support requests from buyers, renters, developers, and residence admins.';

  @override
  String get ticketsEmpty => 'No tickets here';

  @override
  String get ticketStatusOpen => 'Open';

  @override
  String get ticketStatusInProgress => 'In progress';

  @override
  String get ticketStatusResolved => 'Resolved';

  @override
  String get ticketStatusClosed => 'Closed';

  @override
  String get ticketCategoryBilling => 'Billing';

  @override
  String get ticketCategoryModeration => 'Moderation';

  @override
  String get ticketCategoryTechnical => 'Technical';

  @override
  String get ticketCategoryOther => 'Other';

  @override
  String get ticketReplyHint => 'Write a reply…';

  @override
  String get ticketSend => 'Send';

  @override
  String get ticketNew => 'New ticket';

  @override
  String get ticketSubjectHint => 'Subject';

  @override
  String get ticketMessageHint => 'Describe your question or issue';

  @override
  String get supportTicketsSubtitle =>
      'Reach the platform team — billing, moderation, or a technical issue.';
}
