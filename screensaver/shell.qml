import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
  readonly property string homeDir: Quickshell.env("HOME") || ""
  readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || homeDir + "/.local/share"
  readonly property url imageUrl: "file://" + dataHome + "/omarchy-earthview/current.jpg"

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData
      screen: modelData
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      color: "black"
      WlrLayershell.namespace: "omarchy-earthview-screensaver"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

      property bool pointerInitialized: false
      focus: true

      Image {
        anchors.fill: parent
        source: window.imageUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: {
          if (window.pointerInitialized) Qt.quit()
          else window.pointerInitialized = true
        }
        onPressed: Qt.quit()
        onWheel: Qt.quit()
      }

      Keys.onPressed: Qt.quit()
      Component.onCompleted: forceActiveFocus()
    }
  }
}
