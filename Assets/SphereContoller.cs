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
  Vector3 previousSpherePosition = new Vector3(0, 0, 0);
  float previousSphereScale = 0;
  Quaternion previousSphereRotation = new Quaternion(0, 0, 0, 0);

  void Update()
  {
    leftDevice.TryGetFeatureValue(CommonUsages.gripButton, out bool leftGrip);
    rightDevice.TryGetFeatureValue(CommonUsages.gripButton, out bool rightGrip);


    if (leftGrip && rightGrip)
    {
      Vector3 leftHand = leftController.transform.position;
      Vector3 rightHand = rightController.transform.position;

      float deltaScale = (leftHand - rightHand).magnitude / (leftPreviousPosition - rightPreviousPosition).magnitude;
      float newScale = deltaScale * previousSphereScale;

      transform.position = leftHand + (previousSpherePosition - leftHand) * (newScale / previousSphereScale);

      transform.localScale = newScale * new Vector3(1, 1, 1);
      transform.rotation = Quaternion.FromToRotation(Vector3.Normalize(leftPreviousPosition - rightPreviousPosition), Vector3.Normalize(leftHand - rightHand)) * previousSphereRotation;
    }
    else if (leftGrip)
    {
      transform.position = previousSpherePosition + (leftController.transform.position - leftPreviousPosition);
    }
    else if (rightGrip)
    {

      transform.position = previousSpherePosition + (rightController.transform.position - rightPreviousPosition);
    }

    leftPreviousPosition = leftController.transform.position;
    rightPreviousPosition = rightController.transform.position;
    previousSpherePosition = transform.position;
    previousSphereScale = transform.localScale.x;
    previousSphereRotation = transform.rotation;
  }
}
