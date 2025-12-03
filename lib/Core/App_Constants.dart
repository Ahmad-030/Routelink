/// ============================================
/// APP CONSTANTS
/// ============================================

class AppStrings {
  // App Info
  static const String appName = 'RouteLink';
  static const String appTagline = 'Connect. Ride. Arrive.';
  static const String appDescription = 'Real-time ride connection with live route tracking';

  // Onboarding
  static const String onboardingTitle1 = 'Find Your Ride';
  static const String onboardingDesc1 = 'Discover drivers heading your way with real-time route tracking';

  static const String onboardingTitle2 = 'Set Your Price';
  static const String onboardingDesc2 = 'Offer your fare and negotiate directly with drivers';

  static const String onboardingTitle3 = 'Track Live';
  static const String onboardingDesc3 = 'Watch your ride approach in real-time on the map';

  // Auth
  static const String welcome = 'Welcome';
  static const String welcomeBack = 'Welcome Back';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String phoneNumber = 'Phone Number';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String orContinueWith = 'Or continue with';

  // Role Selection
  static const String chooseRole = 'Choose Your Role';
  static const String roleDescription = 'Select how you want to use RouteLink';
  static const String driver = 'Driver';
  static const String passenger = 'Passenger';
  static const String driverDesc = 'Share your route and earn money';
  static const String passengerDesc = 'Find rides along your way';

  // Driver
  static const String setRoute = 'Set Route';
  static const String publishRoute = 'Publish Route';
  static const String startLocation = 'Start Location';
  static const String destination = 'Destination';
  static const String addViaPoint = 'Add Via Point';
  static const String carDetails = 'Car Details';
  static const String carName = 'Car Name';
  static const String carNumber = 'Car Number';
  static const String availableSeats = 'Available Seats';
  static const String suggestedFare = 'Suggested Fare';
  static const String rideRequests = 'Ride Requests';
  static const String accept = 'Accept';
  static const String reject = 'Reject';
  static const String negotiate = 'Negotiate';

  // Passenger
  static const String findRide = 'Find a Ride';
  static const String nearbyDrivers = 'Nearby Drivers';
  static const String offerFare = 'Offer Fare';
  static const String yourOffer = 'Your Offer';
  static const String sendRequest = 'Send Request';
  static const String eta = 'ETA';
  static const String distance = 'Distance';
  static const String seats = 'Seats';

  // Chat
  static const String chat = 'Chat';
  static const String typeMessage = 'Type a message...';
  static const String negotiateRide = 'Negotiate Ride';

  // Common
  static const String confirm = 'Confirm';
  static const String cancel = 'Cancel';
  static const String next = 'Next';
  static const String skip = 'Skip';
  static const String done = 'Done';
  static const String save = 'Save';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String swipeToStart = 'Swipe to Start Riding';
  static const String getStarted = 'Get Started';
}

class AppAssets {
  // Base paths
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _animations = 'assets/animations';
  static const String _3d = 'assets/3d';

  // Images
  static const String logo = '$_images/logo.png';
  static const String logoYellow = '$_images/logo_yellow.png';
  static const String onboarding1 = '$_images/onboarding_1.png';
  static const String onboarding2 = '$_images/onboarding_2.png';
  static const String onboarding3 = '$_images/onboarding_3.png';
  static const String driverRole = '$_images/driver_role.png';
  static const String passengerRole = '$_images/passenger_role.png';
  static const String mapPlaceholder = '$_images/map_placeholder.png';

  // Icons
  static const String appIcon = '$_icons/app_icon.png';
  static const String googleIcon = '$_icons/google.svg';
  static const String appleIcon = '$_icons/apple.svg';
  static const String carIcon = '$_icons/car.svg';
  static const String locationIcon = '$_icons/location.svg';
  static const String routeIcon = '$_icons/route.svg';

  // Animations (Lottie)
  static const String splashAnimation = '$_animations/splash.json';
  static const String carAnimation = '$_animations/car_driving.json';
  static const String loadingAnimation = '$_animations/loading.json';
  static const String successAnimation = '$_animations/success.json';
  static const String locationAnimation = '$_animations/location_pin.json';
  static const String emptyAnimation = '$_animations/empty.json';

  // 3D Models
  static const String car3dModel = '$_3d/car_model.glb';
  static const String sportsCar3d = '$_3d/sports_car.glb';
}

class AppDurations {
  static const Duration splash = Duration(milliseconds: 3000);
  static const Duration animation = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration snackbar = Duration(seconds: 3);
  static const Duration locationUpdate = Duration(seconds: 5);
}

class AppSizes {
  // Padding & Margin
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusRound = 100.0;

  // Icon Sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Button Heights
  static const double buttonHeight = 56.0;
  static const double buttonHeightSm = 44.0;

  // Card
  static const double cardElevation = 8.0;
}