// Copyright Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;

public class CLX : ModuleRules
{
	public CLX(ReadOnlyTargetRules Target) : base(Target)
	{
		CppStandard = CppStandardVersion.Cpp17;
        PCHUsage = ModuleRules.PCHUsageMode.UseExplicitOrSharedPCHs;
		// msgpack11 throws on oversized values. Clang (Mac, Linux) rejects throw
		// while exceptions are off, which is the engine default.
		bEnableExceptions = true;
		
		PublicIncludePaths.AddRange(
			new string[] {
				// ... add public include paths required here ...
			}
			);
				
		
		PrivateIncludePaths.AddRange(
			new string[] {
				// ... add other private include paths required here ...
			}
			);
			
		
		PublicDependencyModuleNames.AddRange(
			new string[]
			{
            "Core",
            "CoreUObject",
            "Engine",
            "Kismet"        // for UBlueprintFunctionLibrary
				// ... add other public dependencies that you statically link with here ...
			}
			);
			
		
		PrivateDependencyModuleNames.AddRange(
			new string[]
			{
            "Sockets",
            "Networking",
                "Slate",
				"SlateCore",

				// ... add private dependencies that you statically link with here ...	
			}
			);
		
		
		DynamicallyLoadedModuleNames.AddRange(
			new string[]
			{
				// ... add any modules that your module loads dynamically here ...
			}
			);
	}
}
