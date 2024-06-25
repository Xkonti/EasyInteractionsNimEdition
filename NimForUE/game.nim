include unrealprelude


uClass USignalTransceiverBase of UActorComponent:
    (Blueprintable, BlueprintType, ClassGroup="Easy Interactions", BlueprintSpawnableComponent)
  
    ufuncs(BlueprintCallable, BlueprintNativeEvent):
        proc getHandledSignalType(): FName =
            log "Please override this function"
            result = FName()
  
    ufuncs(BlueprintCallable):
        proc printMissingTranscieverError() =
            UE_Warn "Receiver field is empty in actor '" & $self.getOwner().getDisplayName() & ". Message was sent by '???' [" & $self.getHandledSignalType() & "]" 


proc getTranscieverComponent(actor: AActorPtr, transcieverClass: UClassPtr): USignalTransceiverBasePtr =
    if not actor.isValid():
        UE_Warn "Actor is invalid in getTranscieverComponent for class " & $transcieverClass.getName()
        return nil

    let components = actor.getComponentsByClass(makeTSubclassOf[USignalTransceiverBase](transcieverClass))
    if components.len == 0:
        UE_Warn "Actor '" & $actor.getDisplayName() & "' has no transcievers of class " & $transcieverClass.getName()
        return nil

    if components.len > 1:
        UE_Warn "Actor '" & $actor.getDisplayName() & "' has more than one transciever of class " & $transcieverClass.getName()
    
    let txComponent = components[0]
    if not txComponent.isValid():
        UE_Warn "Actor '" & $actor.getDisplayName() & "' has invalid transciever of class " & $transcieverClass.getName()
        return nil

    let txSignalComponent = ueCast[USignalTransceiverBase](txComponent)
    if txSignalComponent.isNil():
        UE_Warn "Actor '" & $actor.getDisplayName() & "' has transciever of class " & $transcieverClass.getName() & " that is not a USignalTransceiverBase"
        return nil

    return txSignalComponent



# template CreateTranscieverComponent(classname: untyped, delegateName: untyped, dataType: untyped, signalName: string) =
#     uDelegate delegateName(sender: AActorPtr, receivedData: dataType)

#     uClass classname of USignalTransceiverBase:
#         (Blueprintable, BlueprintType, ClassGroup="Easy Interactions", BlueprintSpawnableComponent)
    
#         uprops(BlueprintAssignable, Category = "Easy Interactions|Signal"):
#             onSignal: delegateName
    
#         ufuncs(BlueprintCallable, BlueprintNativeEvent):
#             proc getHandledSignalType(): FName =
#                 const name = FName(signalName)
#                 result = name
    
#         ufuncs(BlueprintCallable):
#             proc receiveSignal(sender: AActorPtr, receivedData: dataType) =
#                 self.onSignal.broadcast(sender, receivedData)
        
#             proc transmitSignal(sender: AActorPtr, receiver: AActorPtr, dataToTransmit: dataType): bool =
#                 # Obtain receving transciever
#                 let txClass = self.getClass()
#                 let txComponentPtr = getTranscieverComponent(sender, txClass)
#                 if txComponentPtr.isNil:
#                     # TODO: self.printMissingTranscieverError()
#                     return false
#                 let txComponent = ueCast[classname](txComponentPtr)
#                 if txComponent.isNil: 
#                     # TODO: self.printMissingTranscieverError()
#                     return false

#                 # Get the sender
#                 var senderRef = sender
#                 if not sender.isValid():
#                     senderRef = self.getOwner()
                
#                 # Transmit the signal
#                 self.receiveSignal(senderRef, dataToTransmit)
#                 return true

#             proc transmitSignals(sender: AActorPtr, receivers: TArray[AActorPtr], signalsDataToTransmit: TArray[dataType]) =
#                 if receivers.len != signalsDataToTransmit.len:
#                     UE_Warn "TransmitSignals: receivers and signalsDataToTransmit arrays must have the same length"

#                 let itemsCount = min(receivers.len, signalsDataToTransmit.len)

#                 for i in 0..<itemsCount:
#                     let receiver = receivers[i]
#                     let dataToTransmit = signalsDataToTransmit[i]
#                     discard self.transmitSignal(sender, receiver, dataToTransmit)



# CreateTranscieverComponent(UNameSignalTransceiver, FOnNameSignalDelegate, FName, "Name")

uDelegate FOnNameSignalDelegate(sender: AActorPtr, receivedData: FName)

uClass UNameSignalTransceiver of USignalTransceiverBase:
    (Blueprintable, BlueprintType, ClassGroup="Easy Interactions", BlueprintSpawnableComponent)
  
    uprops(BlueprintAssignable, Category = "Easy Interactions|Signal"):
        onSignal: FOnNameSignalDelegate
  
    ufuncs(BlueprintCallable, BlueprintNativeEvent):
        proc getHandledSignalType(): FName =
            const name = FName("Name")
            result = name
  
    ufuncs(BlueprintCallable):
        proc receiveSignal(sender: AActorPtr, receivedData: FName) =
            self.onSignal.broadcast(sender, receivedData)
    
        proc transmitSignal(sender: AActorPtr, receiver: AActorPtr, dataToTransmit: FName): bool =
            # Obtain receving transciever
            let txClass = self.getClass()
            let txComponentPtr = getTranscieverComponent(sender, txClass)
            if txComponentPtr.isNil:
                # TODO: self.printMissingTranscieverError()
                return false
            let txComponent = ueCast[UNameSignalTransceiver](txComponentPtr)
            if txComponent.isNil: 
                # TODO: self.printMissingTranscieverError()
                return false

            # Get the sender
            var senderRef = sender
            if not sender.isValid():
                senderRef = self.getOwner()
            
            # Transmit the signal
            self.receiveSignal(senderRef, dataToTransmit)
            return true

        proc transmitSignals(sender: AActorPtr, receivers: TArray[AActorPtr], signalsDataToTransmit: TArray[FName]) =
            if receivers.len != signalsDataToTransmit.len:
                UE_Warn "TransmitSignals: receivers and signalsDataToTransmit arrays must have the same length"

            let itemsCount = min(receivers.len, signalsDataToTransmit.len)

            for i in 0..<itemsCount:
                let receiver = receivers[i]
                let dataToTransmit = signalsDataToTransmit[i]
                discard self.transmitSignal(sender, receiver, dataToTransmit)

