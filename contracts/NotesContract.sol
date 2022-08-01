// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract NotesContract {
    uint256 public countNotes = 0;

    struct Note {
        uint256 id;
        string title;
        string description;
    }

    //storing notes in a map
    mapping(uint256 => Note) public notes;

    event NoteCreated(uint256 id, string title, string description);
    event NoteDeleted(uint256 id);

    function createNote(string memory _title, string memory _description)
        public
    {
        notes[countNotes] = Note(countNotes, _title, _description);
        emit NoteCreated(countNotes, _title, _description);
        countNotes++;
    }

    function deleteNote(uint256 _id) public {
        delete notes[_id];
        emit NoteDeleted(_id);
        countNotes--;
    }
}
