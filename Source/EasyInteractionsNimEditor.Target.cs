// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;

public class EasyInteractionsNimEditorTarget : TargetRules
{
	public EasyInteractionsNimEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.V5;
		IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_4;
    bOverrideBuildEnvironment = true;
		if (Target.Platform == UnrealTargetPlatform.Win64) {
			AdditionalCompilerArguments = "/Zc:strictStrings-";
		}

		ExtraModuleNames.Add("EasyInteractionsNim");
	}
}
