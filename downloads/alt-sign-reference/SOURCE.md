# Apple capability API facts

Source: https://github.com/SideStore/AltSign/tree/a60e8e2e87ff4934fe38acb1aaf7b9c38d789088
Commit: a60e8e2e87ff4934fe38acb1aaf7b9c38d789088
Purpose: inspect factual feature keys and Apple request schemas; no implementation copied.
License: no license declared in repository metadata; downloaded .h/.m reference files were deleted after inspection and are not redistributed.
Evidence paths:
- AltSign/Capabilities/ALTCapabilities.m: APG3427HIY = app groups; IAD53UNK2F = inter-app audio; gameCenter; INCREASED_MEMORY_LIMIT, INCREASED_MEMORY_LIMIT_DEBUGGING, EXTENDED_VIRTUAL_ADDRESSING enums.
- AltSign/Apple API/ALTAppleAPI.m assignAppID:toGroups: passes applicationGroups as array of group.identifier internal IDs.
Additional default-branch API inspection: https://github.com/SideStore/AltSign/tree/35b68f1aafaa038fd012b11d5acb71e6394c9c25 (develop), Sources/ALTAppleAPI+Operations.swift and ALTCapabilities.swift; inspected in memory only, not redistributed.
