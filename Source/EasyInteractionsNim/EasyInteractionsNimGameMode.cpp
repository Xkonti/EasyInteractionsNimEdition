// Copyright Epic Games, Inc. All Rights Reserved.

#include "EasyInteractionsNimGameMode.h"
#include "EasyInteractionsNimCharacter.h"
#include "UObject/ConstructorHelpers.h"

AEasyInteractionsNimGameMode::AEasyInteractionsNimGameMode()
	: Super()
{
	// set default pawn class to our Blueprinted character
	static ConstructorHelpers::FClassFinder<APawn> PlayerPawnClassFinder(TEXT("/Game/FirstPerson/Blueprints/BP_FirstPersonCharacter"));
	DefaultPawnClass = PlayerPawnClassFinder.Class;

}
