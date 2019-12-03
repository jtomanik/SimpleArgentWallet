# Simple Argent iOSWallet

## Task
Write an application for iOS using Swift, that interacts with Argen contract wallet on the Ropsten testnet.

This deliverable is split into independent features.
1. Show the Wallet Balance
2. Sending ETH
3. Show inbound ERC20 transfers
4. PIN lock screen

## The app
A quick overview of the features

#### Show the Wallet Balance
Apart from showing the token balance, I am also showing a wallet address together with blockly avatar for that address.
I am also querying a current ETHUSD price an show a USD value.

#### Sending ETH
After sending a transaction through web3.swift I'm providing a list of transaction hashes returned. 

#### Show inbound ERC20 transfers
The list shows transactions returned by web3.swift. For each transaction, I'm showing a "from" address a transaction value as well as token's symbol.

#### PIN lock screen
Whenever the app is not active in the foreground the PIN lock screen shows up. For the moment Pin is hardcoded to `1234`.

### Architectural approach
I wanted to present some advantages that architectures based on the State machines, Unidirectional dataflows, Redux and similar posses. This is heavily inspired by the following repos:

[RxFeedback.swift](https://github.com/NoTests/RxFeedback.swift)

[ReactorKit](https://github.com/ReactorKit/ReactorKit)

[ReactiveFeedback](https://github.com/babylonhealth/ReactiveFeedback)

[Workflow](https://github.com/square/workflow)


## Setup
This project has been tested with Xcode 11.2.1 on a MacOS 10.14.5. All Pods are included in this repo.
After cloning into local machine please open `SimpleArgentWallet.xcworkspace` everything should be ready to be built.

## Running the app
After running the app you can end up in the Pin Lock screen. For the moment Pin is hardcoded to `1234`.

### ToDo
There are a few things to improve:

- Improve memory and thread handling
- Add tests
- Add proper documentation
- Add proper error handling
- Add more features 🚀
