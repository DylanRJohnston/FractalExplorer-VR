using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR;
using UnityEngine.XR.Interaction.Toolkit;

public class SphereContoller : MonoBehaviour
{
  // Start is called before the first frame update
  public XRController rightController = null;
  private InputDevice rightDevice;

  public XRController leftController = null;
  private InputDevice leftDevice;


  void Start()
  {
    leftDevice = InputDevices.GetDeviceAtXRNode(leftController.controllerNode);
    rightDevice = InputDevices.GetDeviceAtXRNode(rightController.controllerNode);

  }

  // Update is called once per frame

  Vector3 leftStartingHandPosition = new Vector3(0, 0, 0);
  Vector3 rightStartingHandPosition = new Vector3(0, 0, 0);
  Vector3 startingSpherePosition = new Vector3(0, 0, 0);
  Vector3 startSphereScale = new Vector3(0, 0, 0);
  Quaternion startRotation = new Quaternion(0, 0, 0, 0);
  bool leftStart = false;
  bool rightStart = false;

  void Update()
  {
    leftDevice.TryGetFeatureValue(CommonUsages.gripButton, out bool leftGrip);
    rightDevice.TryGetFeatureValue(CommonUsages.gripButton, out bool rightGrip);

    if (!leftGrip) leftStart = false;
    if (!rightGrip) rightStart = false;

    if ((leftGrip || rightGrip) && (!leftStart && !rightStart))
    {
      startingSpherePosition = transform.position;
      startSphereScale = transform.localScale;
      startRotation = transform.rotation;
    }

    if (leftGrip && !leftStart)
    {
      leftStart = true;
      leftStartingHandPosition = leftController.transform.position;
    }

    if (rightGrip && !rightStart)
    {
      rightStart = true;
      rightStartingHandPosition = rightController.transform.position;
    }

    if (leftGrip && rightGrip)
    {
      Vector3 startVector = leftStartingHandPosition - rightStartingHandPosition;
      Vector3 startMidpoint = (leftStartingHandPosition + rightStartingHandPosition) / 2;

      Vector3 endVector = leftController.transform.position - rightController.transform.position;
      Vector3 endMidpoint = (leftController.transform.position + rightController.transform.position) / 2;

      float startDistance = startVector.magnitude;
      float endDistance = endVector.magnitude;

      float scale = endDistance / startDistance;
      Vector3 translation = endMidpoint - startMidpoint;

      Quaternion rotation = Quaternion.Lerp(Quaternion.identity, Quaternion.FromToRotation(startVector, endVector), 0.5f);

      transform.position = startingSpherePosition + translation;
      transform.localScale = startSphereScale * scale;
      transform.rotation = startRotation * rotation;
    }
    else if (leftGrip)
    {
      transform.position = startingSpherePosition + (leftController.transform.position - leftStartingHandPosition);
    }
    else if (rightGrip)
    {

      transform.position = startingSpherePosition + (rightController.transform.position - rightStartingHandPosition);
    }
  }
}
