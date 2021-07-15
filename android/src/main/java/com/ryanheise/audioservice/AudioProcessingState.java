package com.ryanheise.audioservice;

public enum AudioProcessingState {
    none,
    connecting,
    playing,
    pause,
    ready,
    buffering,
    fastForwarding,
    rewinding,
    skippingToPrevious,
    skippingToNext,
    skippingToQueueItem,
    completed,
    stopped,
    error,
}
