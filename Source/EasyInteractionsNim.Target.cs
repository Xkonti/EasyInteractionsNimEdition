// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;

public class EasyInteractionsNimTarget : TargetRules
{
	public EasyInteractionsNimTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.V5;
		IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_4;
    bOverrideBuildEnvironment = true;
		if (Target.Platform == UnrealTargetPlatform.Win64) {
			AdditionalCompilerArguments = "/Zc:strictStrings-";
		}

		ExtraModuleNames.Add("EasyInteractionsNim");
	}
}
