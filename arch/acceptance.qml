import QtQuick
import QtQuick.Window
Window {
 id: root
 width: 1000; height: 620; visible: true
 color: "#15212f"; title: "Weaselway acceptance check"
 property int clicks: 0
 property int tick: 0
 Timer { interval: 16; running: true; repeat: true; onTriggered: root.tick++ }
 Column {
  x: 36; y: 30; spacing: 24
  Text { text: "WSL Arch · KDE · NVIDIA"; color: "white"; font.pixelSize: 30 }
  Text { text: "Click the button, type below, and resize the Windows viewer."; color: "#d0e1f5"; font.pixelSize: 20 }
  Rectangle {
   width: 260; height: 58; color: "#3b82d0"; radius: 8
   Text { anchors.centerIn: parent; text: "Clicks: " + root.clicks; color: "white"; font.pixelSize: 23 }
   MouseArea { anchors.fill: parent; onClicked: { root.clicks++; console.log("mouse_click", root.clicks) } }
  }
  Rectangle {
   width: 850; height: 70; color: "#f0f5fa"; radius: 6
   TextInput {
    anchors.fill: parent; anchors.margins: 14; font.pixelSize: 25; color: "#172331"
    text: "Type here"; selectByMouse: true
    onTextEdited: console.log("keyboard_text_edited")
   }
  }
  Text { text: "The blue block below moves continuously. No Windows input is injected."; color: "#d0e1f5"; font.pixelSize: 18 }
 }
 Rectangle { x: 36 + (root.tick % 300)*2.6; y: 450; width: 95; height: 95; color: "#36aaff" }
 Text { x: 36; y: 565; text: "Animation ticks: " + root.tick; color: "white"; font.pixelSize: 18 }
}
