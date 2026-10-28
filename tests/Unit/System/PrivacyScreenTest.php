<?php

use Native\Mobile\Facades\System as SystemFacade;
use Native\Mobile\System;
use Native\Mobile\Testing\FakeBridge;

afterEach(fn () => FakeBridge::disable());

it('asks the device to turn the privacy screen on', function () {
    $bridge = FakeBridge::enable()->respondTo('System.SetPrivacyScreen', ['enabled' => true]);

    expect((new System)->setPrivacyScreen(true))->toBeTrue();

    $bridge->assertCalled('System.SetPrivacyScreen', fn (array $params) => $params === ['enabled' => true]);
});

it('asks the device to turn the privacy screen off', function () {
    $bridge = FakeBridge::enable()->respondTo('System.SetPrivacyScreen', ['enabled' => false]);

    expect((new System)->setPrivacyScreen(false))->toBeTrue();

    $bridge->assertCalled('System.SetPrivacyScreen', fn (array $params) => $params === ['enabled' => false]);
});

it('is reachable through the facade', function () {
    $bridge = FakeBridge::enable()->respondTo('System.SetPrivacyScreen', ['enabled' => true]);

    expect(SystemFacade::setPrivacyScreen(true))->toBeTrue();

    $bridge->assertCalledTimes('System.SetPrivacyScreen', 1);
});

it('reports false when the device did not apply it', function (mixed $response) {
    FakeBridge::enable()->respondTo('System.SetPrivacyScreen', $response);

    expect((new System)->setPrivacyScreen(true))->toBeFalse();
})->with([
    'no bridge function' => [null],
    'bridge error' => [['status' => 'error', 'code' => 'INVALID_PARAMETERS', 'message' => 'enabled must be a boolean']],
    'other state applied' => [['enabled' => false]],
    'empty answer' => [[]],
    'not json' => ['nope'],
]);
