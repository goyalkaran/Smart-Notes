import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_notes/notes/note.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

class NotesServicesProvider extends ChangeNotifier {
  List<Note> notes = [];

  //remote procedural call
  final String _rpcURL = "HTTP://127.0.0.1:7545";
  //web-socket url
  final String _wsURL = "ws://127.0.0.1:7545";

  final String _privateKey =
      "861e750a14d0026a0ed8a4ca0ad6bc4b3f7b2b1fe133b9d4d5ff4e1219dd9348";

  late Web3Client _web3client;
  NotesServicesProvider() {
    init();
  }
  Future<void> init() async {
    _web3client = Web3Client(
      _rpcURL,
      http.Client(),
      socketConnector: () {
        return IOWebSocketChannel.connect(_wsURL).cast<String>();
      },
    );
    await getABI();
    await getCredentials();
    await getDeployedContracts();
  }

  late ContractAbi _abiJson;
  late EthereumAddress _contractAddress;
  Future<void> getABI() async {
    String abiFile =
        await rootBundle.loadString("build/contracts/NotesContract.json");
    var jsonABI = jsonDecode(abiFile);
    _abiJson =
        ContractAbi.fromJson(jsonEncode(jsonABI["abi"]), "NotesContract");
    _contractAddress = EthereumAddress.fromHex(jsonABI["networks"]["5777"]);
  }

  late EthPrivateKey _cred;
  Future<void> getCredentials() async {
    _cred = EthPrivateKey.fromHex(_privateKey);
  }

  late DeployedContract _deployedContract;
  late ContractFunction _createNote;
  late ContractFunction _deleteNote;
  late ContractFunction _notes;
  late ContractFunction _notesCount;

  Future<void> getDeployedContracts() async {
    _deployedContract = DeployedContract(_abiJson, _contractAddress);
    _createNote = _deployedContract.function("createnote");
    _deleteNote = _deployedContract.function("deleteNote");
    _notes = _deployedContract.function("notes");
    _notesCount = _deployedContract.function("notesCount");
    await fetchNotes();
  }

  Future<void> fetchNotes() async {
    List totaltaskList = await _web3client.call(
      contract: _deployedContract,
      function: _notesCount,
      params: [],
    );

    int totalTaskLen = totaltaskList[0].toInt();
    notes.clear();

    for (int i = 0; i < totalTaskLen; i++) {
      var temp = await _web3client.call(
        contract: _deployedContract,
        function: _notesCount,
        params: [BigInt.from(i)],
      );
      if (temp[1] != "") {
        notes.add(
          Note(
              id: (temp[0] as BigInt).toInt(),
              title: temp[1],
              description: temp[2]),
        );
      }
    }
    notifyListeners();
  }

  Future<void> addNotes(String title, String description) async {
    await _web3client.sendTransaction(
      _cred,
      Transaction.callContract(
          contract: _deployedContract,
          function: _createNote,
          parameters: [title, description]),
    );
    notifyListeners();
    fetchNotes();
  }
}
