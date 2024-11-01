import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:weather_app/screens/settings%20pages/modify_my_information_screen.dart';
import 'package:weather_app/screens/settings%20pages/modify_my_password_screen.dart';

import '../../../../../core/utils/navigation_with_transition.dart';
import '../../../../authorisation/presentation layer/bloc/disable_account_bloc/disable_account_bloc.dart';
import '../../../../authorisation/presentation layer/bloc/sign_out_bloc/sign_out_bloc.dart';
import '../authorisation/presentation layer/bloc/get_cached_user_info/get_cached_user_bloc.dart';
import '../authorisation/presentation layer/pages/creation account/password_creation_screen.dart';
import '../authorisation/presentation layer/pages/sign_in_screen.dart';
import '../core/colors.dart';
import '../core/widgets/reusable_text.dart';
import '../widgets/Reusable_list_tile.dart';

class OthersScreen extends StatefulWidget {
  const OthersScreen({super.key});

  @override
  State<OthersScreen> createState() => _OthersScreenState();
}

class _OthersScreenState extends State<OthersScreen> {
  @override
  void initState() {
    context.read<GetCachedUserBloc>().add(GetCachedUser());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: primaryColor,
          title: ReusableText(
            text: "Paramètres",
            textSize: 18.sp,
            textColor: Colors.white,
            textFontWeight: FontWeight.w700,
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          )),
      body: Container(
        height: 1.sh,
        width: 1.sw,
        child: BlocConsumer<DisableAccountBloc, DisableAccountState>(
          listener: (context, state) {
            if (state is DisableAccountSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Votre compte a été supprimé avec succès"),
                  backgroundColor: primaryColor,
                ),
              );
              navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                  context, SignInScreen());
            } else if (state is DisableAccountError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: primaryColor,
                ),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 20.w, top: 15.h),
                      child: ReusableText(
                        text: "Mon compte",
                        textSize: 18.sp,
                        textColor: primaryColor,
                        textFontWeight: FontWeight.w700,
                      ),
                    ),

                    /// MES INFORMATIONS
                    BlocBuilder<GetCachedUserBloc, GetCachedUserState>(
                      builder: (context, state) {
                        return ReusableListTile(
                          text: "Mes informations",
                          icon: Icons.person,
                          onTap: () {
                            if (state is GetCachedUserLoaded) {
                              navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                                context,
                                ModifyMyInformationScreen(
                                  user: state.user,
                                ),
                              );
                            }
                          },
                          textColor: primaryColor,
                          textFontWeight: FontWeight.w600,
                          textSize: 16,
                          leadingIcon: Icons.arrow_forward_ios,
                        );
                      },
                    ),
                    ReusableListTile(
                      text: "Modifier mot de passe",
                      icon: Icons.lock,
                      onTap: () {
                        navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                          context,
                          ModifyPasswordScreen(),
                        );
                      },
                      textColor: primaryColor,
                      textFontWeight: FontWeight.w600,
                      textSize: 16,
                      leadingIcon: Icons.arrow_forward_ios,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 15.w, right: 15.w),
                      child: Divider(
                        color: primaryColor,
                        thickness: 1.0.h,
                      ),
                    ),
                    ReusableListTile(
                      paddingLeft: 25.0.w,
                      text: "Supprimer mon compte",
                      icon: FontAwesomeIcons.userXmark,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Supprimer mon compte"),
                              content: Text(
                                  "Êtes-vous sûr de vouloir supprimer votre compte ?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("Annuler"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context
                                        .read<DisableAccountBloc>()
                                        .add(DisableMyAccountEvent());
                                  },
                                  child: Text("Supprimer"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      textColor: primaryColor,
                      textFontWeight: FontWeight.w600,
                      textSize: 16,
                      iconSize: 15.0,
                    ),
                    BlocConsumer<SignOutBloc, SignOutState>(
                      listener: (context, state) {
                        if (state is SignOutSuccess) {
                          navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                              context, SignInScreen());
                        }
                      },
                      builder: (context, state) {
                        if (state is SignOutLoading) {
                          return ReusableListTile(
                            paddingLeft: 25.0.w,
                            text: "Se déconnecter ...",
                            icon: FontAwesomeIcons.signOutAlt,
                            onTap: () {},
                            textColor: primaryColor,
                            textFontWeight: FontWeight.w600,
                            textSize: 16,
                            iconSize: 15.0,
                          );
                        }
                        return ReusableListTile(
                          paddingLeft: 25.0.w,
                          text: "Se déconnecter",
                          icon: FontAwesomeIcons.signOutAlt,
                          onTap: () {
                            context
                                .read<SignOutBloc>()
                                .add(SignOutMyAccountEventPressed());
                          },
                          textColor: primaryColor,
                          textFontWeight: FontWeight.w600,
                          textSize: 16,
                          iconSize: 15.0,
                        );
                      },
                    ),
                  ],
                ),
                if (state is DisableAccountLoading)
                  Center(
                    child: ReusablecircularProgressIndicator(
                      indicatorColor: primaryColor,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
