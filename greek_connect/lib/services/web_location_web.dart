// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

String? gcCurrentBrowserHref() => html.window.location.href;

void gcReplaceBrowserPath(String path) {
  html.window.history.replaceState(null, '', path);
}
