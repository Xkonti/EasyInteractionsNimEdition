uClass USignalTransceiverBase of UActorComponent:
    (Blueprintable, BlueprintType, ClassGroup="Easy Interactions", BlueprintSpawnableComponent)
  
    ufuncs(BlueprintCallable, BlueprintNativeEvent):
        proc getHandledSignalType(): FName =
            log "Please override this function"
            result = FName()
  
    ufuncs(BlueprintCallable):
        proc printMissingTransceiverError() =
            UE_Warn "Receiver field is empty in actor '" & $self.getOwner().getDisplayName() & ". Message was sent by '???' [" & $self.getHandledSignalType() & "]" 

proc getTransceiverComponent[T](actor: AActorPtr, transceiverClass: TSubclassOf[T]): USignalTransceiverBasePtr =
    if not actor.isValid():
        # UE_Warn "Actor is invalid in getTransceiverComponent for class " & $transceiverClass.getName()
        return nil

    let components = actor.getComponentsByClass(transceiverClass)
    if components.len == 0:
        # UE_Warn "Actor '" & $actor.getDisplayName() & "' has no transceivers of class " & $transceiverClass.getName()
        return nil

    if components.len > 1:
        # UE_Warn "Actor '" & $actor.getDisplayName() & "' has more than one transceiver of class " & $transceiverClass.getName()
        discard
    
    let txComponent = components[0]
    if not txComponent.isValid():
        # UE_Warn "Actor '" & $actor.getDisplayName() & "' has invalid transceiver of class " & $transceiverClass.getName()
        return nil

    let txSignalComponent = ueCast[USignalTransceiverBase](txComponent)
    if txSignalComponent.isNil():
        # UE_Warn "Actor '" & $actor.getDisplayName() & "' has transceiver of class " & $transceiverClass.getName() & " that is not a USignalTransceiverBase"
        return nil

    return txSignalComponent



proc getTransceiverComponent(actor: AActorPtr, transceiverClass: UClassPtr): USignalTransceiverBasePtr =
    if not actor.isValid():
        UE_Warn "Actor is invalid in getTransceiverComponent for class " & $transceiverClass.getName()
        return nil

    let components = actor.getComponentsByClass(makeTSubclassOf[USignalTransceiverBase](transceiverClass))
    if components.len == 0:
        UE_Warn "Actor '" & $actor.getDisplayName() & "' has no transceivers of class " & $transceiverClass.getName()
        return nil

    if components.len > 1:
        UE_Warn "Actor '" & $actor.getDisplayName() & "' has more than one transceiver of class " & $transceiverClass.getName()
    
    let txComponent = components[0]
    if not txComponent.isValid():
        UE_Warn "Actor '" & $actor.getDisplayName() & "' has invalid transceiver of class " & $transceiverClass.getName()
        return nil

    let txSignalComponent = ueCast[USignalTransceiverBase](txComponent)
    if txSignalComponent.isNil():
        UE_Warn "Actor '" & $actor.getDisplayName() & "' has transceiver of class " & $transceiverClass.getName() & " that is not a USignalTransceiverBase"
        return nil

    return txSignalComponent



# Template for creating a signal transceiver component
template CreateTransceiverComponent(classname: untyped, delegateName: untyped, dataType: untyped, signalName: string) {.dirty.} =
    uDelegate delegateName(sender: AActorPtr, receivedData: dataType)

    uClass classname of USignalTransceiverBase:
        (Blueprintable, BlueprintType, ClassGroup="Easy Interactions", BlueprintSpawnableComponent)
    
        uprops(BlueprintAssignable, Category = "Easy Interactions|Signal"):
            onSignal: delegateName
    
        ufuncs(BlueprintCallable, BlueprintNativeEvent):
            proc getHandledSignalType(): FName =
                const name = FName(signalName)
                result = name
    
        ufuncs(BlueprintCallable):
            proc receiveSignal(sender: AActorPtr, receivedData: dataType) =
                self.onSignal.broadcast(sender, receivedData)
        
            proc transmitSignal(sender: AActorPtr, receiver: AActorPtr, dataToTransmit: dataType): bool =
                # Obtain receving transceiver
                let txClass = self.getClass()
                let txComponentPtr = getTransceiverComponent(receiver, txClass)
                if txComponentPtr.isNil:
                    # TODO: self.printMissingTransceiverError()
                    return false
                let receiverComponent = ueCast[classname](txComponentPtr)
                if receiverComponent.isNil: 
                    # TODO: self.printMissingTransceiverError()
                    return false

                # Get the sender
                var senderRef = sender
                if not sender.isValid():
                    senderRef = self.getOwner()
                
                # Transmit the signal
                receiverComponent.receiveSignal(senderRef, dataToTransmit)
                return true

            proc transmitSignals(sender: AActorPtr, receivers: TArray[AActorPtr], signalsDataToTransmit: TArray[dataType]) =
                if receivers.len != signalsDataToTransmit.len:
                    UE_Warn "TransmitSignals: receivers and signalsDataToTransmit arrays must have the same length"

                let itemsCount = min(receivers.len, signalsDataToTransmit.len)

                for i in 0..<itemsCount:
                    let receiver = receivers[i]
                    let dataToTransmit = signalsDataToTransmit[i]
                    discard self.transmitSignal(sender, receiver, dataToTransmit)

# VoidSignalTransceiver
uDelegate FOnVoidSignalDelegate(sender: AActorPtr)
uClass UVoidSignalTransceiver of USignalTransceiverBase:
    (Blueprintable, BlueprintType, ClassGroup="Easy Interactions", BlueprintSpawnableComponent)

    uprops(BlueprintAssignable, Category = "Easy Interactions|Signal"):
        onSignal: FOnVoidSignalDelegate

    ufuncs(BlueprintCallable, BlueprintNativeEvent):
        proc getHandledSignalType(): FName =
            const name = n"Void"
            result = name

    ufuncs(BlueprintCallable):
        proc receiveSignal(sender: AActorPtr) =
            self.onSignal.broadcast(sender)
    
        proc transmitSignal(sender: AActorPtr, receiver: AActorPtr): bool =
            # Obtain receving transceiver
            let txClass = self.getClass()
            let txComponentPtr = getTransceiverComponent(sender, txClass)
            if txComponentPtr.isNil:
                # TODO: self.printMissingTransceiverError()
                return false
            let txComponent = ueCast[UVoidSignalTransceiver](txComponentPtr)
            if txComponent.isNil: 
                # TODO: self.printMissingTransceiverError()
                return false

            # Get the sender
            var senderRef = sender
            if not sender.isValid():
                senderRef = self.getOwner()
            
            # Transmit the signal
            self.receiveSignal(senderRef)
            return true

        proc transmitSignals(sender: AActorPtr, receivers: TArray[AActorPtr]) =
            for i in 0..<receivers.len:
                let receiver = receivers[i]
                discard self.transmitSignal(sender, receiver)


CreateTransceiverComponent(UActorClassSignalTransceiver, FOnActorClassSignalDelegate, TSubclassOf[AActor], "ActorClass")
CreateTransceiverComponent(UActorSignalTransceiver, FOnActorSignalDelegate, AActorPtr, "Actor")
CreateTransceiverComponent(UBoolSignalTransceiver, FOnBoolSignalDelegate, bool, "Bool")
CreateTransceiverComponent(UByteSignalTransceiver, FOnByteSignalDelegate, byte, "Byte")
CreateTransceiverComponent(UFloatSignalTransceiver, FOnFloatSignalDelegate, float32, "Float")
CreateTransceiverComponent(UDoubleSignalTransceiver, FOnDoubleSignalDelegate, float, "Double")
CreateTransceiverComponent(UInteger64_SignalTransceiver, FOnInteger64_SignalDelegate, int64, "Integer64")
CreateTransceiverComponent(UIntegerSignalTransceiver, FOnIntegerSignalDelegate, int32, "Integer")
CreateTransceiverComponent(UNameSignalTransceiver, FOnNameSignalDelegate, FName, "Name")
CreateTransceiverComponent(UObjectSignalTransceiver, FOnObjectSignalDelegate, UObjectPtr, "Object")
CreateTransceiverComponent(URotatorSignalTransceiver, FOnRotatorSignalDelegate, FRotator, "Rotator")
CreateTransceiverComponent(UStringSignalTransceiver, FOnStringSignalDelegate, FString, "String")
CreateTransceiverComponent(UTextSignalTransceiver, FOnTextSignalDelegate, FText, "Text")
CreateTransceiverComponent(UTransformSignalTransceiver, FOnTransformSignalDelegate, FTransform, "Transform")
CreateTransceiverComponent(UVectorSignalTransceiver, FOnVectorSignalDelegate, FVector, "Vector")
CreateTransceiverComponent(UInteractionSignalTransceiver, FOnInteractionSignalDelegate, FInteraction, "Interaction")


# Name signal transceiver Blueprint Function Library
uClass UNameSignalTransceiverBlueprintFunctionLibrary of UBlueprintFunctionLibrary:
  ufuncs(Static, BlueprintCallable):
    proc TransmitNameReceiverPairSignal(transceiver: UNameSignalTransceiverPtr, sender: AActorPtr, nameReceiverPair: FNameReceiverPair): bool =
      return transceiver.transmitSignal(sender, nameReceiverPair.target, nameReceiverPair.message)

    proc TransmitNameReceiverPairSignals(transceiver: UNameSignalTransceiverPtr, sender: AActorPtr, nameReceiverPairs: TArray[FNameReceiverPair]) =
      for i in 0..<nameReceiverPairs.len:
        let nameReceiverPair = nameReceiverPairs[i]
        discard transceiver.transmitSignal(sender, nameReceiverPair.target, nameReceiverPair.message)