//=============================================================================
//  MuseScore Movable Do Fingering Plugin
//
//  Copyright (C) 2023 yezhiyi9670
//  based on the following code by Nozomu Yamazaki
//  https://github.com/nozomu-y/MovableDo
//
//  License: http://www.gnu.org/licenses/gpl.html GPL version 2 or higher
//=============================================================================

import QtQuick 2.1
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import MuseScore 3.0
import Muse.UiComponents 1.0

MuseScore {
    version: "1.4"
    description: "This plugin inserts movable do note names derived from the given tonality"
    menuPath: "Plugins.Movable Do Fingering"
    pluginType: "dialog"

    // <MuseScore 4.4 Metadata>
    title: "Movable Do Fingering"
    thumbnailName: "MovableDoFingering.png"
    categoryCode: "composing-arranging-tools"
    // </MuseScore 4.4 Metadata>

    function _quit() {
        (typeof(quit) === 'undefined' ? Qt.quit : quit)();
    }

    // Small note name size is fraction of the full font size.
    property real fontSizeMini: 0.7
    
    // Element type to create
    property real elementType: Element.FINGERING

    function nameChord(notes, text, small, movableDoOffset, notationIndex) {
        var tpcToTonalPitch= {
            "31": "A##",
            "19": "B",
            "7":  "Cb",
            "24": "A#",
            "12": "Bb",
            "0":  "Cbb",
            "29": "G##",
            "17": "A",
            "5":  "Bbb",
            "22": "G#",
            "10": "Ab",
            "27": "F##",
            "15": "G",
            "3":  "Abb",
            "32": "E##",
            "20": "F#",
            "8":  "Gb",
            "25": "E#",
            "13": "F",
            "1":  "Gbb",
            "30": "D##",
            "18": "E",
            "6":  "Fb",
            "23": "D#",
            "11": "Eb",
            "-1": "Fbb",
            "28": "C##",
            "16": "D",
            "4":  "Ebb",
            "33": "B##",
            "21": "C#",
            "9": "Db",
            "26": "B#",
            "14": "C",
            "2":  "Dbb"
        }
        var tonalPitchToMovableDo = {
            'A##': ['t',  't', '7'],
            'A#':  ['li', '♯l', '♯6'],
            'G##': ['l',  'l', '6'],
            'G#':  ['si', '♯s', '♯5'],
            'F##': ['s',  's', '5'],
            'E##': ['fi', '♯f', '♯4'],
            'E#':  ['f',  'f', '4'],
            'D##': ['m',  'm', '3'],
            'D#':  ['ri', '♯r', '♯2'],
            'C##': ['r',  'r', '2'],
            'B##': ['di', '♯d', '♯1'],
            'B#':  ['d',  'd', '1'],
            'B':   ['t',  't', '7'],
            'Bb':  ['ta', '♭t', '♭7'],
            'A':   ['l',  'l', '6'],
            'G':   ['s',  's', '5'],
            'F#':  ['fi', '♯f', '♯4'],
            'F':   ['f',  'f', '4'],
            'E':   ['m',  'm', '3'],
            'Eb':  ['ma', '♭m', '♭3'],
            'D':   ['r',  'r', '2'],
            'C#':  ['di', '♯d', '♯1'],
            'C':   ['d',  'd', '1'],
            'Cb':  ['t',  't', '7'],
            'Cbb': ['ta', '♭t', '♭7'],
            'Bbb': ['l',  'l', '6'],
            'Ab':  ['lo', '♭l', '♭6'],
            'Abb': ['s',  's', '5'],
            'Gb':  ['se', '♭s', '♭5'],
            'Gbb': ['f',  'f', '4'],
            'Fb':  ['m',  'm', '3'],
            'Ebb': ['r',  'r', '2'],
            'Fbb': ['ma', '♭m', '♭3'],
            'Db':  ['ro', '♭r', '♭2'],
            'Dbb': ['d',  'd', '1'],
        }
        var sep = "\n"
        // change to "," if you want them horizontally (anybody?)
        var oct = ""
        var name
        for (var i = 0; i < notes.length; i++) {
            if (!notes[i].visible)
                continue
            // skip invisible notes
            if (text.text)
                // only if text isn't empty
                text.text = sep + text.text
            if (small)
                text.fontSize *= fontSizeMini
            if (typeof notes[i].tpc === "undefined")
                // like for grace notes ?!?
                return
            var tonalPitch = tpcToTonalPitch[String((parseInt(notes[i].tpc) - movableDoOffset + 35 + 1) % 35 - 1)]
            name = tonalPitchToMovableDo[tonalPitch][notationIndex]

            if (notes[i].tieBack !== null) 
                // skip if the note is tied
                continue
            text.text = name + oct + text.text
        }
    }

    function renderGraceNoteNames(cursor, list, text, small, movableDoOffset, notationIndex) {
        if (list.length > 0) {
            // Check for existence.
            // Now render grace note's names...
            for (var chordNum = 0; chordNum < list.length; chordNum++) {
                // iterate through all grace chords
                var chord = list[chordNum]
                // Set note text, grace notes are shown a bit smaller
                nameChord(chord.notes, text, small, movableDoOffset, notationIndex)
                if (text.text)
                    cursor.add(text)
                // X position the note name over the grace chord
                text.offsetX = chord.posX
                switch (cursor.voice) {
                case 1:
                case 3:
                    text.placement = Placement.BELOW
                    break
                }

                // If we consume a STAFF_TEXT we must manufacture a new one.
                if (text.text)
                    text = newElement(elementType) // Make another STAFF_TEXT
            }
        }
        return text
    }

    function nameNotesMovableDo(tonalityText, notationIndex) {
        var movableDoOffset = +tonalityText.split(' ')[0]
        var cursor = curScore.newCursor()
        var startStaff
        var endStaff
        var endTick
        var fullScore = false
        cursor.rewind(1)
        if (!cursor.segment) {
            // no selection
            fullScore = true
            startStaff = 0 // start with 1st staff
            endStaff = curScore.nstaves - 1 // and end with last
        } else {
            startStaff = cursor.staffIdx
            cursor.rewind(2)
            if (cursor.tick === 0) {
                // this happens when the selection includes
                // the last measure of the score.
                // rewind(2) goes behind the last segment (where
                // there's none) and sets tick=0
                endTick = curScore.lastSegment.tick + 1
            } else {
                endTick = cursor.tick
            }
            endStaff = cursor.staffIdx
        }
        console.log(startStaff + " - " + endStaff + " - " + endTick)

        for (var staff = startStaff; staff <= endStaff; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.rewind(1) // beginning of selection
                cursor.voice = voice
                cursor.staffIdx = staff

                if (fullScore)
                    // no selection
                    cursor.rewind(0) // beginning of score
                while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                    if (cursor.element
                            && cursor.element.type === Element.CHORD) {
                        var text = newElement(elementType)
                        // Make a STAFF_TEXT

                        // First...we need to scan grace notes for existence and break them
                        // into their appropriate lists with the correct ordering of notes.
                        var leadingLifo = Array()
                        // List for leading grace notes
                        var trailingFifo = Array()
                        // List for trailing grace notes
                        var graceChords = cursor.element.graceNotes
                        // Build separate lists of leading and trailing grace note chords.
                        if (graceChords.length > 0) {
                            for (var chordNum = 0; chordNum < graceChords.length; chordNum++) {
                                var noteType = graceChords[chordNum].notes[0].noteType
                                if (noteType === NoteType.GRACE8_AFTER
                                        || noteType === NoteType.GRACE16_AFTER
                                        || noteType === NoteType.GRACE32_AFTER) {
                                    trailingFifo.unshift(graceChords[chordNum])
                                } else {
                                    leadingLifo.push(graceChords[chordNum])
                                }
                            }
                        }

                        // Next process the leading grace notes, should they exist...
                        text = renderGraceNoteNames(cursor, leadingLifo,
                                                    text, true, movableDoOffset, notationIndex)

                        // Now handle the note names on the main chord...
                        var notes = cursor.element.notes
                        nameChord(notes, text, false, movableDoOffset,
                                  notationIndex)
                        if (text.text)
                            cursor.add(text)

                        switch (cursor.voice) {
                        case 1:
                        case 3:
                            text.placement = Placement.BELOW
                            break
                        }

                        if (text.text)
                            text = newElement(elementType) // Make another STAFF_TEXT object

                        // Finally process trailing grace notes if they exist...
                        text = renderGraceNoteNames(cursor, trailingFifo,
                                                    text, true, movableDoOffset, notationIndex)
                    } // end if CHORD
                    cursor.next()
                } // end while segment
            } // end for voice
        } // end for staff

        cursor.rewind(1)
        cursor.voice = 0
        cursor.staffIdx = startStaff
        if (fullScore)
            cursor.rewind(0)
        
        // var text = newElement(Element.SYSTEM_TEXT)
        // text.text = tonalityText
        // text.fontSize *= 1.5
        // cursor.add(text)
    }
    
    function getElementTick(element) {
        var segment = element;
        while (segment.parent && segment.type != Element.SEGMENT) {
            segment = segment.parent;
        }
        return segment.tick;
    }

    onRun: {
        var keysig_potential = 0;

        // == 1. Find position
        var cursor = curScore.newCursor();
        var selectedElement = null;
        if(curScore.selection.isRange) {
            cursor.rewind(Cursor.SELECTION_START); // Only works if selection is a range
            selectedElement = cursor.element;
        } else {
            cursor.rewind(Cursor.SCORE_START);
            for (var i in curScore.selection.elements) {
                var element = curScore.selection.elements[i];
                cursor.rewindToTick(getElementTick(element));
                selectedElement = element;
                break;
            }
        }
        keysig_potential = cursor.keySignature;

        // == 2. Make potential in range
        while(keysig_potential < -7) {
            keysig_potential += 12
        }
        while(keysig_potential > +7) {
            keysig_potential -= 12
        }

        // == 3. Set index
        tonality.currentIndex = 7 - keysig_potential
    }

    width: form.width
    height: form.height

    Item {
        id: form
        width: exporterColumn.width + 30
        height: exporterColumn.height + 30
        ColumnLayout {
            id: exporterColumn
            width: grid.width + 32
            Column {
                id: grid
                spacing: 24
                width: 180
                anchors.fill: parent
                anchors.margins: 16
                Column {
                    spacing: 12
                    StyledTextLabel {
                        text: qsTr('Tonality')
                    }
                    StyledDropdown {
                        id: tonality
                        model: [
                            "+7 C♯/a♯",
                            "+6 F♯/d♯",
                            "+5 B/g♯",
                            "+4 E/c♯",
                            "+3 A/f♯",
                            "+2 D/b",
                            "+1 G/e",
                            "0 C/a",
                            "-1 F/d",
                            "-2 B♭/g",
                            "-3 E♭/c",
                            "-4 A♭/f",
                            "-5 D♭/b♭",
                            "-6 G♭/e♭",
                            "-7 C♭/a♭",
                        ]
                        currentIndex: 7
                        onActivated: function(index, value) {
                            currentIndex = index
                        }
                    }
                }
                Column {
                    spacing: 12
                    StyledTextLabel {
                        text: qsTr('Notation')
                    }
                    StyledDropdown {
                        id: notation
                        model: ["Letters-vowel", "Letters", "Numeric"]
                        currentIndex: 1
                        onActivated: function(index, value) {
                            currentIndex = index
                        }
                    }
                }
                FlatButton {
                    id: button
                    text: qsTr("OK")
                    onClicked: {
                        curScore.startCmd()
                        console.log(notation.currentIndex)
                        nameNotesMovableDo(tonality.currentText,
                                            notation.currentIndex)
                        curScore.endCmd()
                        _quit()
                    }
                }
            }
        }
    }

    Settings {
		id: settings
		category: "MovableDoFingeringPlugin"
		property alias notation:	notation.currentIndex
	}
}
