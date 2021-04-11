using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;
using UnityEngine.XR.Interaction.Toolkit;

// class DeviceEvents {
//   DeviceEvents()
// }


public class SphereContoller : MonoBehaviour
{
  // Start is called before the first frame update
  public XRController rightController = null;
  private InputDevice rightDevice;

  public XRController leftController = null;
  private InputDevice leftDevice;

  public XRRig rig = null;


  void Start()
  {
    leftDevice = InputDevices.GetDeviceAtXRNode(leftController.controllerNode);
    rightDevice = InputDevices.GetDeviceAtXRNode(rightController.controllerNode);

  }

  // Update is called once per frame

  Vector3 leftPreviousPosition = new Vector3(0, 0, 0);
  Vector3 rightPreviousPosition = new Vector3(0, 0, 0);

  void Update()
  {
    leftDevice.TryGetFeatureValue(CommonUsages.gripButton, out bool leftGrip);
    rightDevice.TryGetFeatureValue(CommonUsages.gripButton, out bool rightGrip);

    Vector3 leftPosition = leftController.transform.position;
    Vector3 rightPosition = rightController.transform.position;

    Vector3 hands = leftPosition - rightPosition;
    Vector3 previousHands = leftPreviousPosition - rightPreviousPosition;

    if (leftGrip && rightGrip)
    {
      float distanceRatio = hands.magnitude / previousHands.magnitude;

      transform.position = distanceRatio * (transform.position - leftPosition) + leftPosition;
      transform.localScale = distanceRatio * transform.localScale;
      transform.rotation = Quaternion.Lerp(Quaternion.identity, Quaternion.FromToRotation(previousHands, hands), 1 / transform.localScale.x) * transform.rotation;
    }
    else if (leftGrip)
    {
      transform.position += (leftPosition - leftPreviousPosition);
    }
    else if (rightGrip)
    {

      transform.position += (rightPosition - rightPreviousPosition);
    }

    leftPreviousPosition = leftPosition;
    rightPreviousPosition = rightPosition;
  }
}
