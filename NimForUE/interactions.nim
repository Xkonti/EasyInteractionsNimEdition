uDelegate FOnBooleanChanged(newValue: bool)

# Component intended to be used on the player character. Enables tracing for interactive actors in front of the player.
# Requires:
# - Interaction Signal Transceiver Component
uClass UDirectInteractionComponent of UActorComponent:
    (Blueprintable, BlueprintType, ClassGroup="Easy Interactions", BlueprintSpawnableComponent)

    uprops(BlueprintReadWrite, Category = "Internal"):
        selectors: TArray[AActorPtr]

    uprops(BlueprintReadWrite, EditAnywhere, Category = "Setup"):
        bEnabled: bool
        allowInteraction: bool

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

    uprops(BlueprintReadWrite, Category = "Internal"):
        lastSelectedActorComponent: UActorComponentPtr
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

    uprops:
        traceDelayTimerHandle: FTimerHandle

    ufuncs:
        # TODO: How to make this automatically called?
        proc beginPlay() =
            super(self)
            UE_Warn "Begin play happened!"

    ufuncs(BlueprintCallable):
        proc init() =
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

        # proc doTick(deltaSeconds: float32) =
        #     if not self.automaticTracing:
        #         return

        #     # TODO: Add delay timer to prevent tracing too often - this will required begin able to call
        #     # other functions from the same class - something that seems to not work at the moment (all otehr TODOs)

        #     self.lastSelectedActorComponent = self.selectedComponent


        #     # TODO: Place this in a separate function when possible
        #     var outHit: FHitResult
        #     collisionParams: FCollisionQueryParams
        #     collisionParams.addIgnoredActor(self.getOwner())




        #     if foundInteractive:
        #         # Ignore if the seleciton didn't change
        #         if lastSelectedActorComponent == selectedComponent:
        #             return

        #         self.onSelectionStart.broadcast(selectedComponent.getOwner())
        #         lastSelectedActorComponent = selectedComponent

        #     else:
        #         if not lastSelectedActorComponent.isValid():
        #             return

        #         self.onSelectionStop.broadcast(lastSelectedActorComponent.getOwner())
        #         lastSelectedActorComponent = nil
