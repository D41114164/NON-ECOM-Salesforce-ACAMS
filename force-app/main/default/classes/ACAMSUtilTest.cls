@IsTest
private class ACAMSUtilTest {

    @IsTest
    static void getISO2DigitStateTest() {
        System.assert(ACAMSUtil.getISO2DigitState('Illinois') == 'IL');
        System.assert(ACAMSUtil.getISO2DigitState('IL') == 'IL');
    }
}