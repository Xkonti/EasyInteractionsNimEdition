uDelegate FOnBooleanChanged(newValue: bool)

var uniqueId: int32 = 0
proc getUniqueId(): int32 =
    uniqueId = uniqueId + 1
    return uniqueId

# Component intended to be used on the player character. Enables tracing for interactive actors in front of the player.
# Requires:
# - Interaction Signal Transceiver Component
uClass UDirectInteractionComponent of UActorComponent:
    (Blueprintable, BlueprintType, ClassGroup="Easy Interactions", BlueprintSpawnableComponent)

    uprops(BlueprintReadWrite, Category = "Internal"):
        selectors: TArray[AActorPtr]

    uprops(BlueprintReadWrite, EditAnywhere, Category = "Setup"):
        bEnabled: bool = true
        allowInteraction: bool = true

    uprops(BlueprintReadWrite, Category = "Setup"):
        selected: bool

    uprops(BlueprintAssignable, Category = "Interaction"):
        onEnabledChanged: FOnBooleanChanged
        onAllowInteractionChanged: FOnBooleanChanged
        onSelectedChanged: FOnBooleanChanged

    ufuncs(BlueprintCallable):
        proc getSelected(): bool =
            self.selected

        proc addSelectingActor(selectingActor: AActorPtr) =
            self.selectors.addUnique(selectingActor)
            let wasSelected = self.selected
            self.selected = true
            if wasSelected:
                self.onSelectedChanged.broadcast(true)

        proc removeSelectingActor(selectingActor: AActorPtr) =
            self.selectors.remove(selectingActor)
            let wasSelected = self.selected
            self.selected = self.selectors.len > 0
            if wasSelected != self.selected:
                self.onSelectedChanged.broadcast(self.selected)

        proc getEnabled(): bool =
            self.bEnabled

        proc setEnabled(newValue: bool) =
            let prevEnabled = self.bEnabled
            self.bEnabled = newValue
            if prevEnabled != self.bEnabled:
                self.onEnabledChanged.broadcast(self.bEnabled)

        proc toggleEnabled() =
            self.setEnabled(not self.bEnabled)

        proc getAllowInteraction(): bool =
            self.allowInteraction

        proc setAllowInteraction(newValue: bool) =
            let prevAllowInteraction = self.allowInteraction
            self.allowInteraction = newValue
            if prevAllowInteraction != self.allowInteraction:
                self.onAllowInteractionChanged.broadcast(self.allowInteraction)

        # TODO: Figure out how to make this work
        # proc toggleAllowInteraction() =
        #     self.setAllowInteraction(not self.allowInteraction)
        

uDelegate FActorDelegate(actor: AActorPtr)

uClass UTraceInteractor of USceneComponent:
    (Blueprintable, BlueprintType, ClassGroup="Easy Interactions", BlueprintSpawnableComponent)

    uprops(BlueprintReadWrite, EditAnywhere, Category = "Internal"):
        selectedComponent: UDirectInteractionComponentPtr
        delayUuid: int32

    uprops(BlueprintReadWrite, Category = "Internal"):
        lastSelectedActorComponent: UDirectInteractionComponentPtr
        interactionSignalTransceiver: UInteractionSignalTransceiverPtr

    uprops(BlueprintReadWrite, EditAnywhere, Category = "Setup"):
        interactionRangeMin: float32 = 20.0f # Minimum range of interaction
        interactionRangeMax: float32 = 300.0f # Maximum range of interaction
        interactUsingRadius: bool = true # Use sphere trace for interaction? If not, line trace will be used for interaction.
        interactionRadius: float32 = 5.0f # Radius of tracing sphere.
        automaticTracing: bool = true # Automatically trace using time interval. Automatically selects interactive objects.
        traceInterval: float32 = 0.2f # Interval (in seconds) between raytraces. 0 means "every frame".
        ignoredActors: TArray[AActorPtr] # List of actors to ignore while tracing for interactive actors
        debugTraces: EDrawDebugTrace = EDrawDebugTrace.None # Choose type of drawing traces for debugging.
        filterByTags: bool = false # Do filter interaction components by tag? If yes, components not containing any tag from "TagsToSearchFor" array will be ignored in interaction.
        tagsToSearchFor: TArray[FName] # Tags to search for when "FilterByTags" is true.

    uprops(BlueprintAssignable, Category = "Interaction"):
        onSelectionStart: FActorDelegate # Called when new actor is selected.
        onSelectionStop: FActorDelegate # Called when previous actor is not selected anymore.

    ufunc():
        proc getDirectInteractionComponent(hitActor: AActorPtr): UDirectInteractionComponentPtr =
            let directInteractionClass = makeTSubclassOf(UDirectInteractionComponent)

            if not hitActor.isValid():
                return nil

            let components = hitActor.getComponentsByClass(directInteractionClass)
            if components.len == 0:
                return nil
            
            let foundComponent = components[0]
            if not foundComponent.isValid():
                return nil

            let interactionComponent = ueCast[UDirectInteractionComponent](foundComponent)
            if interactionComponent.isNil():
                return nil

            return interactionComponent

    ufuncs:
        # TODO: How to make this automatically called?
        # proc beginPlay() =
        #     super(self)
        #     UE_Warn "Begin play happened!"

        proc trace(outHit: var FHitResult): bool =
            let worldContextObject = self.getWorld()

            let ownerActor = self.getOwner()

            # Line trace

            let forwardVector = self.getForwardVector()
            let worldLocation = self.getComponentLocation()
            var rayStart = (forwardVector * self.interactionRangeMin) + worldLocation
            var rayEnd = (forwardVector * self.interactionRangeMax) + worldLocation
            
            let isHit = lineTraceSingle(
                worldContextObject,
                rayStart, rayEnd,
                ETraceTypeQuery.TraceTypeQuery1,
                false,
                self.ignoredActors,
                self.debugTraces,
                outHit, true)

            proc failTrace() =
                if not self.selectedComponent.isValid():
                    return;
                self.selectedComponent.removeSelectingActor(ownerActor)
                self.selectedComponent = nil
                return

            if not isHit:
                failTrace()
                return false

            # Get the DirectInteractionComponent from the hit component
            let outHitComponent = ueCast[UActorComponent](outHit.component.get())
            let outHitActor = outHitComponent.getOwner()
            let interactionComponent = self.getDirectInteractionComponent(outHitActor)
            if interactionComponent.isNil() or not interactionComponent.getEnabled():
                failTrace()
                return false

            # Check if tags provided given the filtering is enabled
            if self.filterByTags:
                var hasTag = false
                for tag in self.tagsToSearchFor:
                    if outHitComponent.componentHasTag(tag):
                        hasTag = true
                        break;

                if not hasTag:
                    failTrace()
                    return false

            # Save target as selected
            if self.selectedComponent != interactionComponent:
                if not self.selectedComponent.isNil():
                    self.selectedComponent.removeSelectingActor(ownerActor)
                interactionComponent.addSelectingActor(ownerActor)

            return true

    ufuncs(BlueprintCallable):
        proc init() =
            self.delayUuid = getUniqueId()
            let txClass = makeTSubclassOf(UInteractionSignalTransceiver)
            let txComponentPtr = getTransceiverComponent(self.getOwner(), txClass)
            if txComponentPtr.isNil:
                # TODO: self.printMissingTransceiverError()
                UE_Warn "Could not find interaction transceiver component"
                self.destroyComponent()
                return
            let interactionTxComponent = ueCast[UInteractionSignalTransceiver](txComponentPtr)
            if interactionTxComponent.isNil: 
                # TODO: self.printMissingTransceiverError()
                UE_Warn "Could not cast interaction transceiver component"
                self.destroyComponent()
                return

            UE_Warn "Interaction transceiver component found"
            self.interactionSignalTransceiver = interactionTxComponent

        proc doTick(deltaSeconds: float32) =
            if not self.automaticTracing:
                return

            # A sketchy useage of the Blurprints' Delay node
            let latentInfo = FLatentActionInfo(
                linkage: 0, # Is it supposed to be 0?
                uuid: self.delayUuid, # What does it do and where to get it from?
                executionFunction: n"afterDelay",  # This is typically 0 unless you're doing something special
                callbackTarget: self,
            )

            delay(self.getWorld(), self.traceInterval, latentInfo)

    ufuncs():
        proc afterDelay() =
            UE_Warn "After delay"
            self.lastSelectedActorComponent = self.selectedComponent

            # Tracing
            var outHit: FHitResult
            let foundInteractive = self.trace(outHit) 

            # Selection
            if foundInteractive:
                # Ignore if the seleciton didn't change
                if self.lastSelectedActorComponent == self.selectedComponent:
                    return

                let selectedActor = self.selectedComponent.getOwner() 
                self.onSelectionStart.broadcast(selectedActor)
                self.lastSelectedActorComponent = self.selectedComponent

            else:
                if not self.lastSelectedActorComponent.isValid():
                    return

                self.onSelectionStop.broadcast(self.lastSelectedActorComponent.getOwner())
                self.lastSelectedActorComponent = nil
