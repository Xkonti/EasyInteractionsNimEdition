uEnum EInteractionType:
  (BlueprintType)
  Use
  Take

uStruct FInteraction:
  (BlueprintType)
  uprop(BlueprintReadWrite, EditAnywhere):
    interactionType: EInteractionType = Use
    isInteractionStart: bool = false

uStruct FNameReceiverPair:
  (BlueprintType)
  uprop(BlueprintReadWrite, EditAnywhere):
    message: FName = n""
    target: AActorPtr = nil