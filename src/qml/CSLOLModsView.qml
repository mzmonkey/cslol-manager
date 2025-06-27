import QtQuick 2.15
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

ColumnLayout {
    id: cslolModsView
    spacing: 5

    property bool showImage: true
    property int columnCount: 1
    property bool isBussy: false
    property real rowHeight: 0
    property string search: ""

    signal modRemoved(string fileName)

    signal modExport(string fileName)

    signal modEdit(string fileName)

    signal importFile(string file)

    signal installFantomeZip()

    signal createNewMod()

    signal tryRefresh()

    function initializeMods(mods, profileMods, folders) {
        // Clear existing models
        cslolModsViewModel.clear()
        cslolFoldersModel.clear()

        // Add folders first
        for (let folderPath in folders) {
            let folderInfo = folders[folderPath]
            cslolFoldersModel.append({
                "FolderPath": folderPath,
                "FolderName": folderPath.split('/').pop(),
                "Expanded": false,
                "ModCount": folderInfo.mods.length
            })
        }

        // Add mods
        for (let fileName in mods) {
            let enabled = fileName in profileMods
            addMod(fileName, mods[fileName], enabled, folders)
        }
    }

    function addMod(fileName, info, enabled, folders) {
        let infoData = {
            "FileName": fileName,
            "Name": info["Name"],
            "Version": info["Version"],
            "Description": info["Description"],
            "Author": info["Author"],
            "Home": info["Home"],
            "Heart": info["Heart"],
            "Image": CSLOLUtils.toFile("./installed/" + fileName + "/META/image.png"),
            "Enabled": enabled === true,
            "FolderPath": getFolderForMod(fileName, folders)
        }
        if (searchMatches(infoData)) {
            cslolModsViewModel.append(infoData)
            resortMod_model(cslolModsViewModel.count - 1, cslolModsViewModel)
        } else {
            cslolModsViewModel2.append(infoData)
        }
    }

    function getFolderForMod(fileName, folders) {
        for (let folderPath in folders) {
            let folderInfo = folders[folderPath]
            if (folderInfo.mods.includes(fileName)) {
                return folderPath
            }
        }
        return ""
    }

    function toggleFolder(folderPath) {
        for (let i = 0; i < cslolFoldersModel.count; i++) {
            let folder = cslolFoldersModel.get(i)
            if (folder.FolderPath === folderPath) {
                cslolFoldersModel.setProperty(i, "Expanded", !folder.Expanded)
                break
            }
        }
    }

    function isModInExpandedFolder(mod) {
        if (!mod.FolderPath) return true

        for (let i = 0; i < cslolFoldersModel.count; i++) {
            let folder = cslolFoldersModel.get(i)
            if (folder.FolderPath === mod.FolderPath) {
                return folder.Expanded
            }
        }
        return false
    }

    function loadProfile(mods) {
        loadProfile_model(mods, cslolModsViewModel)
        loadProfile_model(mods, cslolModsViewModel2)
    }

    function updateModInfo(fileName, info) {
        let i0 = updateModInfo_model(fileName, info, cslolModsViewModel);
        if (i0 !== -1) {
            if (!searchMatches(info)) {
                cslolModsViewModel2.append(cslolModsViewModel.get(i0))
                cslolModsViewModel.remove(i0)
            } else {
                resortMod_model(i0, cslolModsViewModel)
            }
        }

        let i1 = updateModInfo_model(fileName, info, cslolModsViewModel2);
        if (i1 !== -1) {
            if (searchMatches(info)) {
                cslolModsViewModel.append(cslolModsViewModel2.get(i1))
                cslolModsViewModel2.remove(i1)
                resortMod_model(cslolModsViewModel.count - 1, cslolModsViewModel)
            }
        }
    }

    function saveProfile() {
        let mods = {}
        saveProfile_model(mods, cslolModsViewModel)
        saveProfile_model(mods, cslolModsViewModel2)
        return mods
    }

    function searchMatches(info) {
        return search == "" || info["Name"].toLowerCase().search(search) !== -1 || info["Description"].toLowerCase().search(search) !== -1
    }

    function searchUpdate() {
        let i = 0;
        while (i < cslolModsViewModel2.count) {
            let obj = cslolModsViewModel2.get(i)
            if (searchMatches(obj)) {
                cslolModsViewModel.append(obj);
                cslolModsViewModel2.remove(i, 1)
                resortMod_model(cslolModsViewModel.count - 1, cslolModsViewModel)
            } else {
                i++;
            }
        }
        let j = 0;
        while (j < cslolModsViewModel.count) {
            let obj2 = cslolModsViewModel.get(j)
            if (!searchMatches(obj2)) {
                cslolModsViewModel2.append(obj2)
                cslolModsViewModel.remove(j, 1)
            } else {
                j++;
            }
        }
    }

    function resortMod_model(index, model) {
        let info = model.get(index)
        for (let i = 0; i < index; i++) {
            if (model.get(i)["Name"].toLowerCase() >= info["Name"].toLowerCase()) {
                model.move(index, i, 1);
                return i;
            }
        }
        for (let j = model.count - 1; j > index; j--) {
            if (model.get(j)["Name"].toLowerCase() <= info["Name"].toLowerCase()) {
                model.move(index, j, 1);
                return j;
            }
        }
        return index;
    }

    function saveProfile_model(mods, model) {
        let modsCount = model.count
        for (let i = 0; i < modsCount; i++) {
            let obj = model.get(i)
            if (obj["Enabled"] === true) {
                mods[obj["FileName"]] = true
            }
        }
    }

    function loadProfile_model(mods, model) {
        let modsCount = model.count
        for (let i = 0; i < modsCount; i++) {
            let obj = model.get(i)
            model.setProperty(i, "Enabled", mods[obj["FileName"]] === true)
        }
        checkedUpdate()
    }

    function updateModInfo_model(fileName, info, model) {
        let modsCount = model.count
        for (let i = 0; i < modsCount; i++) {
            let obj = model.get(i)
            if (obj["FileName"] === fileName) {
                if (obj["Name"] !== info["Name"]) {
                    model.setProperty(i, "Name", info["Name"])
                }
                if (obj["Version"] !== info["Version"]) {
                    model.setProperty(i, "Version", info["Version"])
                }
                if (obj["Description"] !== info["Description"]) {
                    model.setProperty(i, "Description", info["Description"])
                }
                if (obj["Author"] !== info["Author"]) {
                    model.setProperty(i, "Author", info["Author"])
                }
                if (obj["Home"] !== info["Home"]) {
                    model.setProperty(i, "Home", info["Home"])
                }
                if (obj["Heart"] !== info["Heart"]) {
                    model.setProperty(i, "Heart", info["Heart"])
                }
                return i;
            }
        }
        return -1;
    }

    function checkAll(doEnable) {
        for (let i = 0; i < cslolModsViewModel.count; i++) {
            let obj = cslolModsViewModel.get(i)
            if (obj["Enabled"] !== doEnable) {
                cslolModsViewModel.setProperty(i, "Enabled", doEnable)
            }
        }
        for (let j = 0; j < cslolModsViewModel2.count; j++) {
            let obj = cslolModsViewModel2.get(j)
            if (obj["Enabled"] !== doEnable) {
                cslolModsViewModel2.setProperty(i, "Enabled", doEnable)
            }
        }
    }

    function checkedUpdate() {
        let hasEnabled = false
        let hasDisabled = false
        for (let i = 0; i < cslolModsViewModel.count; i++) {
            let obj = cslolModsViewModel.get(i)
            if (obj["Enabled"]) {
                hasEnabled = true;
            } else {
                hasDisabled = true;
            }
        }
        for (let j = 0; j < cslolModsViewModel2.count; j++) {
            let obj = cslolModsViewModel2.get(j)
            if (obj["Enabled"]) {
                hasEnabled = true;
            } else {
                hasDisabled = true;
            }
        }
        let newState = Qt.PartiallyChecked
        if (hasEnabled && !hasDisabled) {
            newState = Qt.Checked;
        }
        if (!hasEnabled && hasDisabled) {
            newState = Qt.Unchecked;
        }
        if (enableAllCheckbox.checkState !== newState) {
            enableAllCheckbox.checkState = newState
        }
    }

    function refreshedMods(mods) {
        for (let fileName in mods) {
            if (updateModInfo_model(fileName, mods[fileName], cslolModsViewModel) === -1) {
                if (updateModInfo_model(fileName, mods[fileName], cslolModsViewModel2) === -1) {
                    addMod(fileName, mods[fileName], false)
                }
            }
        }
        let i = 0;
        while (i < cslolModsViewModel2.count) {
            let obj = cslolModsViewModel2.get(i)
            if (!(obj["FileName"] in mods)) {
                cslolModsViewModel2.remove(i, 1)
            } else {
                i++;
            }
        }
        let j = 0;
        while (j < cslolModsViewModel.count) {
            let obj2 = cslolModsViewModel.get(j)
            if (!(obj2["FileName"] in mods)) {
                cslolModsViewModel.remove(j, 1)
            } else {
                j++;
            }
        }
    }

    ListModel {
        id: cslolModsViewModel
    }

    ListModel {
        id: cslolModsViewModel2
    }

    ListModel {
        id: cslolFoldersModel
    }

    ScrollView {
        id: cslolModsScrollView
        Layout.fillHeight: true
        Layout.fillWidth: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        padding: ScrollBar.vertical.width
        spacing: 5

        ListView {
            id: cslolModsViewView
            model: ListModel {
                id: combinedModel
            }

            Component.onCompleted: rebuildCombinedModel()

            function rebuildCombinedModel() {
                combinedModel.clear()

                // Add folders and their mods
                let processedMods = new Set()

                for (let i = 0; i < cslolFoldersModel.count; i++) {
                    let folder = cslolFoldersModel.get(i)

                    // Add folder header
                    combinedModel.append({
                        "ItemType": "folder",
                        "FolderPath": folder.FolderPath,
                        "FolderName": folder.FolderName,
                        "Expanded": folder.Expanded,
                        "ModCount": folder.ModCount
                    })

                    // Add mods if folder is expanded
                    if (folder.Expanded) {
                        for (let j = 0; j < cslolModsViewModel.count; j++) {
                            let mod = cslolModsViewModel.get(j)
                            if (mod.FolderPath === folder.FolderPath) {
                                let modItem = Object.assign({}, mod)
                                modItem.ItemType = "mod"
                                modItem.ModelIndex = j
                                combinedModel.append(modItem)
                                processedMods.add(mod.FileName)
                            }
                        }
                    }
                }

                // Add standalone mods (not in folders)
                for (let k = 0; k < cslolModsViewModel.count; k++) {
                    let mod = cslolModsViewModel.get(k)
                    if (!mod.FolderPath && !processedMods.has(mod.FileName)) {
                        let modItem = Object.assign({}, mod)
                        modItem.ItemType = "mod"
                        modItem.ModelIndex = k
                        combinedModel.append(modItem)
                    }
                }
            }

            DropArea {
                id: fileDropArea
                anchors.fill: parent
                enabled: !isBussy
                onDropped: function(drop) {
                    if (drop.hasUrls && drop.urls.length > 0) {
                        cslolModsView.importFile(CSLOLUtils.fromFile(drop.urls[0]))
                    }
                }
            }

            delegate: Item {
                width: cslolModsViewView.width
                height: model.ItemType === "folder" ? 40 : 75

                // Folder delegate
                Pane {
                    visible: model.ItemType === "folder"
                    anchors.fill: parent
                    Material.elevation: 1
                    Material.background: Material.primaryColor

                    Row {
                        anchors.fill: parent
                        anchors.margins: 5

                        ToolButton {
                            text: model.Expanded ? "\uf107" : "\uf105"
                            font.family: "FontAwesome"
                            onClicked: {
                                cslolModsView.toggleFolder(model.FolderPath)
                                cslolModsViewView.rebuildCombinedModel()
                            }
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.FolderName + " (" + model.ModCount + " mods)"
                            color: "white"
                            font.bold: true
                        }
                    }
                }

                // Mod delegate
                Pane {
                    visible: model.ItemType === "mod"
                    anchors.fill: parent
                    anchors.leftMargin: model.FolderPath ? 20 : 0
                    enabled: !isBussy
                    Material.elevation: 3

                    Row {
                        width: parent.width
                        property string modName: model.Name || ""

                        CheckBox {
                            width: parent.width * 0.3
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.Name || ""
                            checked: model.Enabled || false
                            onCheckedChanged: {
                                if (model.ModelIndex !== undefined) {
                                    cslolModsViewModel.setProperty(model.ModelIndex, "Enabled", checked)
                                    cslolModsView.checkedUpdate()
                                }
                            }
                            CSLOLToolTip {
                                text: qsTr("Enable this mod")
                                visible: parent.hovered
                            }
                        }

                        Column {
                            width: parent.width * 0.29
                            anchors.verticalCenter: parent.verticalCenter
                            Label {
                                horizontalAlignment: Text.AlignHCenter
                                text: "V" + (model.Version || "") + " by " + (model.Author || "")
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Label {
                                horizontalAlignment: Text.AlignHCenter
                                text: model.Description || ""
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                width: parent.width
                            }
                        }

                        Row {
                            width: parent.width * 0.4
                            layoutDirection: Qt.RightToLeft
                            anchors.verticalCenter: parent.verticalCenter

                            ToolButton {
                                text: "\uf00d"
                                font.family: "FontAwesome"
                                onClicked: {
                                    let modName = model.FileName
                                    if (model.ModelIndex !== undefined) {
                                        cslolModsViewModel.remove(model.ModelIndex, 1)
                                        cslolModsView.modRemoved(modName)
                                        cslolModsViewView.rebuildCombinedModel()
                                    }
                                }
                                CSLOLToolTip {
                                    text: qsTr("Remove this mod")
                                    visible: parent.hovered
                                }
                            }
                            ToolButton {
                                text: "\uf1c6"
                                font.family: "FontAwesome"
                                onClicked: {
                                    cslolModsView.modExport(model.FileName)
                                }
                                CSLOLToolTip {
                                    text: qsTr("Export this mod")
                                    visible: parent.hovered
                                }
                            }
                            ToolButton {
                                text: "\uf044"
                                font.family: "FontAwesome"
                                onClicked: {
                                    cslolModsView.modEdit(model.FileName)
                                }
                                CSLOLToolTip {
                                    text: qsTr("Edit this mod")
                                    visible: parent.hovered
                                }
                            }
                            ToolButton {
                                text: "\uf059"
                                font.family: "FontAwesome"
                                onClicked: {
                                    let url = model.Home
                                    if (window.validUrl.test(url)) {
                                        Qt.openUrlExternally(url)
                                    }
                                }
                                CSLOLToolTip {
                                    text: qsTr("Mod updates")
                                    visible: parent.hovered
                                }
                            }
                            ToolButton {
                                text: "\uf004"
                                font.family: "FontAwesome"
                                onClicked: {
                                    let url = model.Heart
                                    if (window.validUrl.test(url)) {
                                        Qt.openUrlExternally(url)
                                    }
                                }
                                CSLOLToolTip {
                                    text: qsTr("Support this author")
                                    visible: parent.hovered
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        spacing: cslolModsScrollView.spacing
        Layout.fillWidth:  true
        Layout.margins: cslolModsScrollView.padding * 2

        CheckBox {
            id: enableAllCheckbox
            enabled: !isBussy
            tristate: true
            checkState: Qt.PartiallyChecked
            nextCheckState: function() {
                return checkState === Qt.Checked ? Qt.Unchecked : Qt.Checked
            }
            CSLOLToolTip {
                text: qsTr("Enable all mods")
                visible: parent.hovered
            }
            onCheckedChanged: {
                if (checkState !== Qt.PartiallyChecked) {
                    cslolModsView.checkAll(enableAllCheckbox.checked)
                }
            }
        }
        TextField {
            id: cslolModsViewSearchBox
            enabled: !isBussy || window.patcherRunning
            Layout.fillWidth:  true
            placeholderText: "Search..."
            onTextEdited: {
                search = text.toLowerCase()
                searchUpdate()
            }
        }
        RoundButton {
            enabled: !isBussy
            text: "\uf021"
            font.family: "FontAwesome"
            onClicked: cslolModsView.tryRefresh()
            Material.background: Material.primaryColor
            CSLOLToolTip {
                text: qsTr("Refresh")
                visible: parent.hovered
            }
        }
        RoundButton {
            enabled: !isBussy
            text: "\uf067"
            font.family: "FontAwesome"
            onClicked: cslolModsView.createNewMod()
            Material.background: Material.primaryColor
            CSLOLToolTip {
                text: qsTr("Create new mod")
                visible: parent.hovered
            }
        }
        RoundButton {
            enabled: !isBussy
            text: "\uf1c6"
            font.family: "FontAwesome"
            onClicked: cslolModsView.installFantomeZip()
            Material.background: Material.primaryColor
            CSLOLToolTip {
                text: qsTr("Import new mod")
                visible: parent.hovered
            }
        }
    }
}
