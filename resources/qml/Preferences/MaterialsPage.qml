// Copyright (c) 2018 Ultimaker B.V.
// Uranium is released under the terms of the LGPLv3 or higher.

import QtQuick 2.8
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura


Item
{
    id: base
    property var resetEnabled: false  // Keep PreferencesDialog happy

    UM.I18nCatalog { id: catalog; name: "cura"; }

    Cura.NewMaterialsModel {
        id: materialsModel
    }

    Label {
        id: titleLabel

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 5 * screenScaleFactor
        }

        font.pointSize: 18
        text: catalog.i18nc("@title:tab", "Materials")
    }

    property var hasCurrentItem: materialListView.currentItem != null

    property var currentItem: {
        var current_index = materialListView.currentIndex;
        return materialsModel.getItem(current_index);
    }

    property var isCurrentItemActivated: {
        const extruder_position = Cura.ExtruderManager.activeExtruderIndex;
        const root_material_id = Cura.MachineManager.currentRootMaterialId[extruder_position];
        return base.currentItem.root_material_id == root_material_id;
    }

    Row  // Button Row
    {
        id: buttonRow
        anchors {
            left: parent.left
            right: parent.right
            top: titleLabel.bottom
        }
        height: childrenRect.height

        // Activate button
        Button {
            text: catalog.i18nc("@action:button", "Activate")
            iconName: "list-activate"
            enabled: !isCurrentItemActivated
            onClicked: {
                forceActiveFocus()

                const extruder_position = Cura.ExtruderManager.activeExtruderIndex;
                Cura.MachineManager.setMaterial(extruder_position, base.currentItem.container_node);
            }
        }

        // Create button
        Button {
            text: catalog.i18nc("@action:button", "Create")
            iconName: "list-add"
            onClicked: {
                forceActiveFocus()
                // TODO
            }
        }

        // Duplicate button
        Button {
            text: catalog.i18nc("@action:button", "Duplicate");
            iconName: "list-add"
            enabled: base.hasCurrentItem
            onClicked: {
                forceActiveFocus();
                Cura.ContainerManager.duplicateMaterial(base.currentItem.container_node);
            }
        }

        // Remove button
        Button {
            text: catalog.i18nc("@action:button", "Remove")
            iconName: "list-remove"
            enabled: base.hasCurrentItem && !base.currentItem.is_read_only && !base.isCurrentItemActivated
            onClicked: {
                forceActiveFocus();
                confirmRemoveMaterialDialog.open();
            }
        }

        // Import button
        Button {
            text: catalog.i18nc("@action:button", "Import")
            iconName: "document-import"
            onClicked: {
                forceActiveFocus()
                // TODO
            }
            visible: true
        }

        // Export button
        Button {
            text: catalog.i18nc("@action:button", "Export")
            iconName: "document-export"
            onClicked: {
                forceActiveFocus()
                // TODO
            }
            enabled: currentItem != null
        }
    }

    MessageDialog
    {
        id: confirmRemoveMaterialDialog

        icon: StandardIcon.Question;
        title: catalog.i18nc("@title:window", "Confirm Remove")
        text: catalog.i18nc("@label (%1 is object name)", "Are you sure you wish to remove %1? This cannot be undone!").arg(base.currentItem.name)
        standardButtons: StandardButton.Yes | StandardButton.No
        modality: Qt.ApplicationModal

        onYes:
        {
            Cura.ContainerManager.removeMaterial(base.currentItem.container_node);
            // reset current item to the first if available
            materialListView.currentIndex = 0;
        }
    }


    Item {
        id: contentsItem

        anchors {
            top: titleLabel.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 5 * screenScaleFactor
            bottomMargin: 0
        }

        clip: true
    }

    Item
    {
        anchors {
            top: buttonRow.bottom
            topMargin: UM.Theme.getSize("default_margin").height
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        SystemPalette { id: palette }

        Label
        {
            id: captionLabel
            anchors {
                top: parent.top
                left: parent.left
            }
            visible: text != ""
            text: {
                // OLD STUFF
                var caption = catalog.i18nc("@action:label", "Printer") + ": " + Cura.MachineManager.activeMachineName;
                if (Cura.MachineManager.hasVariants)
                {
                    caption += ", " + Cura.MachineManager.activeDefinitionVariantsName + ": " + Cura.MachineManager.activeVariantName;
                }
                return caption;
            }
            width: materialScrollView.width
            elide: Text.ElideRight
        }

        ScrollView
        {
            id: materialScrollView
            anchors {
                top: captionLabel.visible ? captionLabel.bottom : parent.top
                topMargin: captionLabel.visible ? UM.Theme.getSize("default_margin").height : 0
                bottom: parent.bottom
                left: parent.left
            }

            Rectangle {
                parent: viewport
                anchors.fill: parent
                color: palette.light
            }

            width: true ? (parent.width * 0.4) | 0 : parent.width

            ListView
            {
                id: materialListView

                model: materialsModel

                section.property: "brand"
                section.criteria: ViewSection.FullString
                section.delegate: Rectangle
                {
                    width: materialScrollView.width
                    height: childrenRect.height
                    color: palette.light

                    Label
                    {
                        anchors.left: parent.left
                        anchors.leftMargin: UM.Theme.getSize("default_lining").width
                        text: section
                        font.bold: true
                        color: palette.text
                    }
                }

                delegate: Rectangle
                {
                    width: materialScrollView.width
                    height: childrenRect.height
                    color: ListView.isCurrentItem ? palette.highlight : (model.index % 2) ? palette.base : palette.alternateBase

                    Row
                    {
                        spacing: (UM.Theme.getSize("default_margin").width / 2) | 0
                        anchors.left: parent.left
                        anchors.leftMargin: UM.Theme.getSize("default_margin").width
                        anchors.right: parent.right
                        Rectangle
                        {
                            width: Math.floor(parent.height * 0.8)
                            height: Math.floor(parent.height * 0.8)
                            color: model.color_code
                            border.color: parent.ListView.isCurrentItem ? palette.highlightedText : palette.text;
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label
                        {
                            width: Math.floor((parent.width * 0.3))
                            text: model.material
                            elide: Text.ElideRight
                            font.italic: {  // TODO: make it easier
                                const extruder_position = Cura.ExtruderManager.activeExtruderIndex;
                                const root_material_id = Cura.MachineManager.currentRootMaterialId[extruder_position];
                                return model.root_material_id == root_material_id
                            }
                            color: parent.ListView.isCurrentItem ? palette.highlightedText : palette.text;
                        }
                        Label
                        {
                            text: (model.name != model.material) ? model.name : ""
                            elide: Text.ElideRight
                            font.italic: {  // TODO: make it easier
                                const extruder_position = Cura.ExtruderManager.activeExtruderIndex;
                                const root_material_id = Cura.MachineManager.currentRootMaterialId[extruder_position];
                                return model.root_material_id == root_material_id;
                            }
                            color: parent.ListView.isCurrentItem ? palette.highlightedText : palette.text;
                        }
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked: {
                            parent.ListView.view.currentIndex = model.index;
                        }
                    }
                }

                onCurrentIndexChanged:
                {
                    var model = materialsModel.getItem(currentIndex);
                    materialDetailsView.containerId = model.container_id;
                    materialDetailsView.currentMaterialNode = model.container_node;

                    detailsPanel.updateMaterialPropertiesObject();
                }
            }
        }


        Item
        {
            id: detailsPanel

            anchors {
                left: materialScrollView.right
                leftMargin: UM.Theme.getSize("default_margin").width
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }

            function updateMaterialPropertiesObject()
            {
                var currentItem = materialsModel.getItem(materialListView.currentIndex);

                materialProperties.name = currentItem.name;
                materialProperties.guid = currentItem.guid;

                materialProperties.brand = currentItem.brand ? currentItem.brand : "Unknown";
                materialProperties.material = currentItem.material ? currentItem.material : "Unknown";
                materialProperties.color_name = currentItem.color_name ? currentItem.color_name : "Yellow";
                materialProperties.color_code = currentItem.color_code ? currentItem.color_code : "yellow";

                materialProperties.description = currentItem.description ? currentItem.description : "";
                materialProperties.adhesion_info = currentItem.adhesion_info ? currentItem.adhesion_info : "";

                if(currentItem.properties != undefined && currentItem.properties != null)
                {
                    materialProperties.density = currentItem.density ? currentItem.density : 0.0;
                    materialProperties.diameter = currentItem.diameter ? currentItem.diameter : 0.0;
                    materialProperties.approximate_diameter = currentItem.approximate_diameter ? currentItem.approximate_diameter : "0";
                }
                else
                {
                    materialProperties.density = 0.0;
                    materialProperties.diameter = 0.0;
                    materialProperties.approximate_diameter = "0";
                }
            }

            Item
            {
                anchors.fill: parent

                Item    // Material title Label
                {
                    id: profileName

                    width: parent.width
                    height: childrenRect.height

                    Label {
                        text: materialProperties.name
                        font: UM.Theme.getFont("large")
                    }
                }

                MaterialView    // Material detailed information view below the title Label
                {
                    id: materialDetailsView
                    anchors
                    {
                        left: parent.left
                        right: parent.right
                        top: profileName.bottom
                        topMargin: UM.Theme.getSize("default_margin").height
                        bottom: parent.bottom
                    }

                    editingEnabled: base.currentItem != null && !base.currentItem.is_read_only

                    properties: materialProperties
                    containerId: base.currentItem != null ? base.currentItem.id : ""
                    currentMaterialNode: base.currentItem

                    property alias pane: base
                }

                QtObject
                {
                    id: materialProperties

                    property string guid: "00000000-0000-0000-0000-000000000000"
                    property string name: "Unknown";
                    property string profile_type: "Unknown";
                    property string brand: "Unknown";
                    property string material: "Unknown";  // This needs to be named as "material" to be consistent with
                                                          // the material container's metadata entry

                    property string color_name: "Yellow";
                    property color color_code: "yellow";

                    property real density: 0.0;
                    property real diameter: 0.0;
                    property string approximate_diameter: "0";

                    property real spool_cost: 0.0;
                    property real spool_weight: 0.0;
                    property real spool_length: 0.0;
                    property real cost_per_meter: 0.0;

                    property string description: "";
                    property string adhesion_info: "";
                }
            }
        }
    }
}
